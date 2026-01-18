import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    @State private var serverVersion: String?
    @State private var showAppChangelog = false
    @State private var showServerChangelog = false
    @State private var appChangelogContent: String?
    @State private var serverChangelogContent: String?
    @State private var serverChangelogLoading = false
    @State private var serverChangelogError: String?

    private var appVersion: String {
        if let path = Bundle.main.path(forResource: "VERSION", ofType: nil),
           let version = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
            return version
        }
        // Fallback to bundle version if VERSION file not found
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationView {
            List {
                // User info section
                if let user = authViewModel.currentUser {
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Edit profile section
                    Section {
                        NavigationLink(destination: ProfileEditView().environmentObject(authViewModel)) {
                            HStack {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.green)
                                Text("Profil bearbeiten")
                            }
                        }
                    }
                }

                // App info section
                Section(header: Text("App Info")) {
                    Button {
                        showAppChangelog = true
                    } label: {
                        HStack {
                            Text("App-Version")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button {
                        showServerChangelog = true
                        Task {
                            await loadServerChangelog()
                        }
                    } label: {
                        HStack {
                            Text("Server-Version")
                                .foregroundColor(.primary)
                            Spacer()
                            if let version = serverVersion {
                                Text(version)
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(APIClient.shared.serverHost)
                            .foregroundColor(.secondary)
                    }
                }

                // Logout section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            if authViewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Abmelden")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(authViewModel.isLoading)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profil")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Abmelden?"),
                    message: Text("Moechten Sie sich wirklich abmelden?"),
                    primaryButton: .destructive(Text("Abmelden")) {
                        Task {
                            await authViewModel.logout()
                        }
                    },
                    secondaryButton: .cancel(Text("Abbrechen"))
                )
            }
            .sheet(isPresented: $showAppChangelog) {
                ChangelogView(
                    title: "App Changelog",
                    content: appChangelogContent,
                    isLoading: false,
                    error: appChangelogContent == nil ? "Changelog nicht gefunden" : nil
                )
            }
            .sheet(isPresented: $showServerChangelog) {
                ChangelogView(
                    title: "Server Changelog",
                    content: serverChangelogContent,
                    isLoading: serverChangelogLoading,
                    error: serverChangelogError
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await loadServerVersion()
        }
        .onAppear {
            loadAppChangelog()
        }
    }

    private func loadServerVersion() async {
        do {
            let response: ServerVersionResponse = try await APIClient.shared.request(.serverVersion, body: nil)
            serverVersion = response.version
        } catch {
            serverVersion = "?"
        }
    }

    private func loadAppChangelog() {
        if let path = Bundle.main.path(forResource: "CHANGELOG", ofType: "md"),
           let content = try? String(contentsOfFile: path, encoding: .utf8) {
            appChangelogContent = content
        }
    }

    private func loadServerChangelog() async {
        serverChangelogLoading = true
        serverChangelogError = nil
        serverChangelogContent = nil

        do {
            let response: ServerChangelogResponse = try await APIClient.shared.request(.serverChangelog, body: nil)
            serverChangelogContent = response.changelog
        } catch {
            serverChangelogError = "Changelog konnte nicht geladen werden"
        }

        serverChangelogLoading = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
