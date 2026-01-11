import Foundation

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable?) async throws -> T
    func requestVoid(_ endpoint: APIEndpoint, body: Encodable?) async throws
}

final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    // Keep a strong reference to the delegate to prevent deallocation
    private let redirectBlocker: RedirectBlocker

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

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws -> T {
        // Use string concatenation to preserve query parameters (appendingPathComponent encodes ? and &)
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 301, 302, 303, 307, 308:
            // Redirect typically means session expired (redirect to login)
            throw APIError.unauthorized
        case 401:
            throw APIError.unauthorized
        case 403:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.forbidden(errorResponse.error)
            }
            throw APIError.forbidden("Sie haben keine Berechtigung fuer diese Aktion")
        case 404:
            throw APIError.notFound
        case 400:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.error)
            }
            throw APIError.badRequest("Ungueltite Anfrage")
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func requestVoid(_ endpoint: APIEndpoint, body: Encodable? = nil) async throws {
        // Use string concatenation to preserve query parameters (appendingPathComponent encodes ? and &)
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 301, 302, 303, 307, 308:
            // Redirect typically means session expired (redirect to login)
            throw APIError.unauthorized
        case 401:
            throw APIError.unauthorized
        case 403:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.forbidden(errorResponse.error)
            }
            throw APIError.forbidden("Sie haben keine Berechtigung fuer diese Aktion")
        case 404:
            throw APIError.notFound
        case 400:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.error)
            }
            throw APIError.badRequest("Ungueltite Anfrage")
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func clearCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
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
