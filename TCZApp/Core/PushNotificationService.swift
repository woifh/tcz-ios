import Foundation
import UserNotifications
import UIKit

/// Service for managing push notification registration and handling
@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let apiClient: APIClientProtocol
    private let keychainService: KeychainServiceProtocol

    private override init() {
        self.apiClient = APIClient.shared
        self.keychainService = KeychainService.shared
        super.init()
    }

    // MARK: - Authorization

    /// Request notification permission from user
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await updateAuthorizationStatus()

            if granted {
                registerForRemoteNotifications()
            }

            return granted
        } catch {
            #if DEBUG
            print("Push notification authorization error: \(error)")
            #endif
            return false
        }
    }

    /// Check current authorization status
    func updateAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Registration

    /// Register with APNs
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called when APNs registration succeeds
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        // Store locally
        if let tokenData = tokenString.data(using: .utf8) {
            try? keychainService.save(key: "apnsDeviceToken", data: tokenData)
        }

        // Send to server if user is authenticated
        Task {
            await sendTokenToServer(tokenString)
        }
    }

    /// Called when APNs registration fails
    func didFailToRegisterForRemoteNotifications(error: Error) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif
    }

    // MARK: - Server Communication

    /// Send device token to server
    func sendTokenToServer(_ token: String) async {
        do {
            let request = DeviceTokenRequest(deviceToken: token, platform: "ios")
            try await apiClient.requestVoid(.registerDeviceToken, body: request)
            #if DEBUG
            print("Device token registered with server")
            #endif
        } catch {
            #if DEBUG
            print("Failed to register device token: \(error)")
            #endif
        }
    }

    /// Remove device token from server (on logout)
    func unregisterFromServer() async {
        guard let token = deviceToken else { return }

        do {
            try await apiClient.requestVoid(.unregisterDeviceToken(token: token), body: nil)
            #if DEBUG
            print("Device token unregistered from server")
            #endif
        } catch {
            #if DEBUG
            print("Failed to unregister device token: \(error)")
            #endif
        }

        // Clear local storage
        keychainService.delete(key: "apnsDeviceToken")
        deviceToken = nil
    }

    /// Re-register token after login (if already authorized)
    func reregisterIfNeeded() async {
        await updateAuthorizationStatus()

        if authorizationStatus == .authorized {
            // Check for stored token
            if let tokenData = keychainService.load(key: "apnsDeviceToken"),
               let token = String(data: tokenData, encoding: .utf8) {
                deviceToken = token
                await sendTokenToServer(token)
            } else {
                registerForRemoteNotifications()
            }
        }
    }
}

// MARK: - Request Model

struct DeviceTokenRequest: Encodable {
    let deviceToken: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case platform
    }
}
