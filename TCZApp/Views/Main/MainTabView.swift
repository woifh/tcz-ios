import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var reservationsViewModel = ReservationsViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var selectedTab: TabItem = .dashboard
    @State private var showingLogin = false

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: dashboardViewModel)
                case .reservations:
                    if authViewModel.isAuthenticated {
                        ReservationsView(viewModel: reservationsViewModel)
                    }
                case .favorites:
                    if authViewModel.isAuthenticated {
                        FavoritesView(viewModel: favoritesViewModel)
                    }
                case .profile:
                    if authViewModel.isAuthenticated {
                        ProfileView()
                    } else {
                        LoginPlaceholderView(showingLogin: $showingLogin)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar with profile picture support
            CustomTabBar(
                selectedTab: $selectedTab,
                isAuthenticated: authViewModel.isAuthenticated,
                currentUser: authViewModel.currentUser
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingLogin) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showingLogin = false
            } else {
                // Reset to dashboard when logged out
                selectedTab = .dashboard
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
