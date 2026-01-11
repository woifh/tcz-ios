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
    private let keychainService: KeychainService

    init(apiClient: APIClientProtocol = APIClient.shared,
         keychainService: KeychainService = .shared) {
        self.apiClient = apiClient
        self.keychainService = keychainService

        // Check for stored session on init
        checkStoredSession()
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

        // Clear cookies
        if let client = apiClient as? APIClient {
            client.clearCookies()
        }

        isLoading = false
    }

    private func checkStoredSession() {
        if let userData = keychainService.load(key: "currentUser"),
           let user = try? JSONDecoder().decode(Member.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
    }
}
