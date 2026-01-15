import Foundation
import Combine

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Member?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: APIClientProtocol
    private let keychainService: KeychainServiceProtocol

    init(apiClient: APIClientProtocol = APIClient.shared,
         keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.apiClient = apiClient
        self.keychainService = keychainService

        // Check for stored session on init
        checkStoredSession()

        // Handle session expiration from API calls
        apiClient.setOnUnauthorized { [weak self] in
            self?.handleSessionExpired()
        }
    }

    private func handleSessionExpired() {
        // Clear local state without calling server logout
        currentUser = nil
        isAuthenticated = false
        keychainService.delete(key: "currentUser")
        keychainService.delete(key: "accessToken")
        apiClient.clearAuth()
    }

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Bitte E-Mail und Passwort eingeben"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = LoginRequest(email: email, password: password)
            let response: LoginResponse = try await apiClient.request(.login, body: credentials)

            // Store user info
            currentUser = response.user
            isAuthenticated = true

            // Store credentials securely for session restoration
            if let userData = try? JSONEncoder().encode(response.user) {
                try? keychainService.save(key: "currentUser", data: userData)
            }

            // Store and set access token for Bearer authentication
            if let tokenData = response.accessToken.data(using: .utf8) {
                try? keychainService.save(key: "accessToken", data: tokenData)
            }
            apiClient.setAccessToken(response.accessToken)

        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Anmeldung fehlgeschlagen"
        }

        isLoading = false
    }

    func logout() async {
        isLoading = true

        // Try to logout on server, but don't fail if it doesn't work
        do {
            try await apiClient.requestVoid(.logout, body: nil)
        } catch {
            print("Logout error: \(error)")
        }

        // Clear local state
        currentUser = nil
        isAuthenticated = false
        keychainService.delete(key: "currentUser")
        keychainService.delete(key: "accessToken")

        // Clear auth (token and cookies)
        apiClient.clearAuth()

        isLoading = false
    }

    private func checkStoredSession() {
        // Restore user data
        if let userData = keychainService.load(key: "currentUser"),
           let user = try? JSONDecoder().decode(Member.self, from: userData) {
            currentUser = user
            isAuthenticated = true

            // Restore access token for Bearer authentication
            if let tokenData = keychainService.load(key: "accessToken"),
               let token = String(data: tokenData, encoding: .utf8) {
                apiClient.setAccessToken(token)
            }
        }
    }
}
