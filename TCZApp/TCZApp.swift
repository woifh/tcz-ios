import SwiftUI

@main
struct TCZApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(appTheme.colorScheme)
                .transaction { $0.animation = nil }
        }
    }
}
