import SwiftUI

@main
struct TCZApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var pushService = PushNotificationService.shared
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(pushService)
                .preferredColorScheme(appTheme.colorScheme)
                .transaction { $0.animation = nil }
                .task {
                    await pushService.updateAuthorizationStatus()
                }
                .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
                    Task {
                        if isAuthenticated {
                            await pushService.reregisterIfNeeded()
                        } else {
                            await pushService.unregisterFromServer()
                        }
                    }
                }
        }
    }
}
