import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var reservationsViewModel = ReservationsViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var showingLogin = false

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Uebersicht", systemImage: "calendar")
                }

            if authViewModel.isAuthenticated {
                ReservationsView(viewModel: reservationsViewModel)
                    .tabItem {
                        Label("Buchungen", systemImage: "list.bullet")
                    }

                FavoritesView(viewModel: favoritesViewModel)
                    .tabItem {
                        Label("Favoriten", systemImage: "star")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person")
                    }
            } else {
                // Login placeholder tab for anonymous users
                LoginPlaceholderView(showingLogin: $showingLogin)
                    .tabItem {
                        Label("Anmelden", systemImage: "person.badge.key")
                    }
            }
        }
        .tint(.green)
        .sheet(isPresented: $showingLogin) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showingLogin = false
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

                Text("Melden Sie sich an, um Plaetze zu buchen, Ihre Buchungen zu verwalten und Favoriten zu speichern.")
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
