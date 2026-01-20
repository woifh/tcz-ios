import SwiftUI

/// Tab items for authenticated users
enum TabItem: Int, CaseIterable {
    case dashboard = 0
    case reservations = 1
    case favorites = 2
    case profile = 3

    var title: String {
        switch self {
        case .dashboard: return "Uebersicht"
        case .reservations: return "Buchungen"
        case .favorites: return "Favoriten"
        case .profile: return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "calendar"
        case .reservations: return "list.bullet"
        case .favorites: return "star"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .dashboard: return "calendar"
        case .reservations: return "list.bullet"
        case .favorites: return "star.fill"
        case .profile: return "person.fill"
        }
    }
}

/// Custom tab bar that supports profile picture display
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    let isAuthenticated: Bool
    let currentUser: Member?

    var body: some View {
        HStack(spacing: 0) {
            // Dashboard tab (always visible)
            TabBarButton(
                tab: .dashboard,
                isSelected: selectedTab == .dashboard,
                currentUser: nil
            ) {
                selectedTab = .dashboard
            }

            if isAuthenticated {
                // Authenticated user tabs
                TabBarButton(
                    tab: .reservations,
                    isSelected: selectedTab == .reservations,
                    currentUser: nil
                ) {
                    selectedTab = .reservations
                }

                TabBarButton(
                    tab: .favorites,
                    isSelected: selectedTab == .favorites,
                    currentUser: nil
                ) {
                    selectedTab = .favorites
                }

                TabBarButton(
                    tab: .profile,
                    isSelected: selectedTab == .profile,
                    currentUser: currentUser
                ) {
                    selectedTab = .profile
                }
            } else {
                // Anonymous user: login tab
                AnonymousLoginTabButton(
                    isSelected: selectedTab == .profile
                ) {
                    selectedTab = .profile
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

/// Tab bar button for standard tabs
struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let currentUser: Member?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if tab == .profile, let user = currentUser {
                    // Profile picture for profile tab
                    ProfilePictureView(member: user, size: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                        )
                } else {
                    // Standard icon for other tabs
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22))
                }

                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .green : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Login tab button for anonymous users
struct AnonymousLoginTabButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "person.badge.key")
                    .font(.system(size: 22))

                Text("Anmelden")
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .green : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Authenticated") {
    VStack {
        Spacer()
        CustomTabBar(
            selectedTab: .constant(.profile),
            isAuthenticated: true,
            currentUser: nil
        )
    }
}

#Preview("Anonymous") {
    VStack {
        Spacer()
        CustomTabBar(
            selectedTab: .constant(.dashboard),
            isAuthenticated: false,
            currentUser: nil
        )
    }
}
