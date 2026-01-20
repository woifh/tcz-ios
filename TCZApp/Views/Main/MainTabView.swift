import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var reservationsViewModel = ReservationsViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var showingLogin = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Uebersicht", systemImage: "calendar")
                }
                .tag(0)

            if authViewModel.isAuthenticated {
                ReservationsView(viewModel: reservationsViewModel)
                    .tabItem {
                        Label("Buchungen", systemImage: "list.bullet")
                    }
                    .tag(1)

                FavoritesView(viewModel: favoritesViewModel)
                    .tabItem {
                        Label("Favoriten", systemImage: "star")
                    }
                    .tag(2)
            } else {
                // Login placeholder tab for anonymous users
                LoginPlaceholderView(showingLogin: $showingLogin)
                    .tabItem {
                        Label("Anmelden", systemImage: "person.badge.key")
                    }
                    .tag(1)
            }
        }
        .tint(.green)
        .sheet(isPresented: $showingLogin) {
            LoginView()
                .environmentObject(authViewModel)
                .preferredColorScheme(appTheme.colorScheme)
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showingLogin = false
                // Return to Dashboard tab on login
                selectedTab = 0
            } else {
                // Return to Dashboard tab on logout
                selectedTab = 0
            }
        }
    }
}

/// Placeholder view that triggers the login sheet
struct LoginPlaceholderView: View {
    @Binding var showingLogin: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.key")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Anmelden")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Melde dich an, um Plätze zu reservieren, deine Reservierungen zu verwalten und Favoriten zu speichern.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Button(action: {
                    showingLogin = true
                }) {
                    Text("Jetzt anmelden")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            .navigationTitle("Anmelden")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Automatically show login when tab is selected
            showingLogin = true
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
