import Foundation

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable?) async throws -> T
    func requestVoid(_ endpoint: APIEndpoint, body: Encodable?) async throws
    func setAccessToken(_ token: String?)
    func clearAuth()
    func setOnUnauthorized(_ handler: @escaping () -> Void)

    // Profile picture methods
    func uploadProfilePicture(memberId: String, imageData: Data) async throws -> ProfilePictureResponse
    func fetchProfilePicture(memberId: String) async throws -> Data
    func deleteProfilePicture(memberId: String) async throws
}

final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    // Keep a strong reference to the delegate to prevent deallocation
    private let redirectBlocker: RedirectBlocker
    // Bearer token for API authentication
    private var accessToken: String?
    // Callback for handling unauthorized responses (session expired)
    private var onUnauthorized: (() -> Void)?

    private init() {
        // Development URL - use your Mac's IP for device testing, 127.0.0.1 for simulator
        // To find your Mac's IP: run `ipconfig getifaddr en0` in Terminal
        // Change to "https://tcz.pythonanywhere.com" for production
        #if DEBUG
        self.baseURL = URL(string: "http://10.0.0.147:5001")!  // Mac's local IP for device testing
        #else
        self.baseURL = URL(string: "https://woifh.pythonanywhere.com")!
        #endif

        // Configure session with cookie storage for Flask session management
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        // Use delegate to block redirects so we can detect 302 auth failures
        self.redirectBlocker = RedirectBlocker()
        self.session = URLSession(configuration: configuration, delegate: self.redirectBlocker, delegateQueue: nil)

        // Configure decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 first
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try YYYY-MM-DD format
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
    }

    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }

    func setOnUnauthorized(_ handler: @escaping () -> Void) {
        self.onUnauthorized = handler
    }

    private func buildRequest(for endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        // Use string concatenation to preserve query parameters (appendingPathComponent encodes ? and &)
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws -> T {
        try await performRequest(endpoint, body: body, attempt: 1)
    }

    private func performRequest<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable?, attempt: Int) async throws -> T {
        let request = try buildRequest(for: endpoint, body: body)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("🔴 Decoding error for \(endpoint.path):")
                print("   Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("   Response JSON: \(jsonString.prefix(1000))")
                }
                #endif
                throw APIError.decodingError(error)
            }
        case 301, 302, 303, 307, 308:
            // Redirect typically means session expired (redirect to login)
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 401:
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 403:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.forbidden(errorResponse.error)
            }
            throw APIError.forbidden("Du hast keine Berechtigung für diese Aktion")
        case 404:
            throw APIError.notFound
        case 400:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.fullErrorMessage)
            }
            throw APIError.badRequest("Ungültige Anfrage")
        case 429:
            throw APIError.rateLimited
        default:
            // Retry once on transient server errors (500, 502, 503, 504) for GET requests
            let isRetryableError = [500, 502, 503, 504].contains(httpResponse.statusCode)
            if isRetryableError && endpoint.method == .get && attempt < 2 {
                #if DEBUG
                print("⚠️ Server error \(httpResponse.statusCode) for \(endpoint.path), retrying...")
                #endif
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                return try await performRequest(endpoint, body: body, attempt: attempt + 1)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func requestVoid(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws {
        let request = try buildRequest(for: endpoint, body: body)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 301, 302, 303, 307, 308:
            // Redirect typically means session expired (redirect to login)
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 401:
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 403:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.forbidden(errorResponse.error)
            }
            throw APIError.forbidden("Du hast keine Berechtigung für diese Aktion")
        case 404:
            throw APIError.notFound
        case 400:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.fullErrorMessage)
            }
            throw APIError.badRequest("Ungueltige Anfrage")
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    var serverHost: String {
        baseURL.host ?? baseURL.absoluteString
    }

    func clearCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
    }

    func clearAuth() {
        accessToken = nil
        clearCookies()
    }

    // MARK: - Profile Picture Methods

    func uploadProfilePicture(memberId: String, imageData: Data) async throws -> ProfilePictureResponse {
        guard let url = URL(string: baseURL.absoluteString + "/api/members/\(memberId)/profile-picture") else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(ProfilePictureResponse.self, from: data)
        case 401:
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 400:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.fullErrorMessage)
            }
            throw APIError.badRequest("Ungültige Anfrage")
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func fetchProfilePicture(memberId: String) async throws -> Data {
        guard let url = URL(string: baseURL.absoluteString + "/api/members/\(memberId)/profile-picture") else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func deleteProfilePicture(memberId: String) async throws {
        guard let url = URL(string: baseURL.absoluteString + "/api/members/\(memberId)/profile-picture") else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            let handler = self.onUnauthorized
            DispatchQueue.main.async { handler?() }
            throw APIError.unauthorized
        case 400, 404:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.fullErrorMessage)
            }
            throw APIError.badRequest("Fehler beim Löschen")
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

/// Helper class to prevent URLSession from following redirects
/// This allows us to detect 302 responses (session expired) instead of silently following to login page
private class RedirectBlocker: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Return nil to prevent following the redirect
        completionHandler(nil)
    }
}
