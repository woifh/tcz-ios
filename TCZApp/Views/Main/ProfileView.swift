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
    @State private var appVersion: String = "?"
    @State private var isConfirmingPayment = false
    @State private var paymentError: String?
    @State private var showingPaymentConfirmationAlert = false
    @State private var isResendingVerification = false
    @State private var verificationError: String?
    @State private var showingVerificationSentAlert = false

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

                    // Payment status section (only when fee is unpaid)
                    if let feePaid = user.feePaid, !feePaid {
                        Section(header: Text("Mitgliedsbeitrag")) {
                            HStack {
                                Text("Status")
                                Spacer()
                                if user.hasPendingPaymentConfirmation {
                                    Label("Bestätigung angefragt", systemImage: "clock.fill")
                                        .foregroundColor(.orange)
                                } else {
                                    Label("Offen", systemImage: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }

                            if !user.hasPendingPaymentConfirmation {
                                Button {
                                    showingPaymentConfirmationAlert = true
                                } label: {
                                    HStack {
                                        Spacer()
                                        if isConfirmingPayment {
                                            ProgressView()
                                        } else {
                                            Text("Zahlung bestätigen")
                                        }
                                        Spacer()
                                    }
                                }
                                .disabled(isConfirmingPayment)
                            }

                            if let error = paymentError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                // Email verification section
                if let user = authViewModel.currentUser,
                   user.shouldShowEmailVerificationReminder {
                    Section(header: Text("E-Mail-Bestätigung")) {
                        HStack {
                            Text("Status")
                            Spacer()
                            Label("Nicht bestätigt", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }

                        Text("Du erhältst keine E-Mail-Benachrichtigungen, bis deine E-Mail-Adresse bestätigt wurde.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            Task { await resendVerificationEmail() }
                        } label: {
                            HStack {
                                Spacer()
                                if isResendingVerification {
                                    ProgressView()
                                } else {
                                    Text("Bestätigungs-E-Mail erneut senden")
                                }
                                Spacer()
                            }
                        }
                        .disabled(isResendingVerification)

                        if let error = verificationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
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
            .alert("Abmelden?", isPresented: $showingLogoutAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Abmelden", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text("Möchtest du dich wirklich abmelden?")
            }
            .alert("Zahlung bestätigen?", isPresented: $showingPaymentConfirmationAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Bestätigen") {
                    Task { await confirmPayment() }
                }
            } message: {
                Text("Hiermit bestätigst du, dass du deinen Mitgliedsbeitrag bezahlt hast. Die Bestätigung wird an den Vorstand gesendet.")
            }
            .alert("E-Mail gesendet", isPresented: $showingVerificationSentAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Eine Bestätigungs-E-Mail wurde an deine Adresse gesendet. Bitte klicke auf den Link in der E-Mail, um deine Adresse zu bestätigen.")
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
            loadAppVersion()
            loadAppChangelog()
        }
    }

    private func loadAppVersion() {
        // Get build number from bundle (CURRENT_PROJECT_VERSION)
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Parse version from CHANGELOG.md (single source of truth)
        if let path = Bundle.main.path(forResource: "CHANGELOG", ofType: "md"),
           let content = try? String(contentsOfFile: path, encoding: .utf8),
           let unreleasedRange = content.range(of: "## [Unreleased]") {
            // Find first "## [" after [Unreleased]
            let searchStart = unreleasedRange.upperBound
            if let startRange = content.range(of: "## [", range: searchStart..<content.endIndex),
               let endRange = content.range(of: "]", range: startRange.upperBound..<content.endIndex) {
                let version = String(content[startRange.upperBound..<endRange.lowerBound])
                if version.contains(".") {
                    appVersion = "\(version).0 (\(buildNumber))"
                    return
                }
            }
        }
        // Fallback to bundle version
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        appVersion = "\(shortVersion) (\(buildNumber))"
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

    private func confirmPayment() async {
        isConfirmingPayment = true
        paymentError = nil

        do {
            let _: PaymentConfirmationResponse = try await APIClient.shared.request(.confirmPayment, body: nil)
            // Refresh user data to update payment status (will show pending state)
            await authViewModel.refreshCurrentUser()
        } catch let apiError as APIError {
            paymentError = apiError.localizedDescription
        } catch {
            paymentError = "Fehler beim Anfordern der Zahlungsbestätigung"
        }

        isConfirmingPayment = false
    }

    private func resendVerificationEmail() async {
        isResendingVerification = true
        verificationError = nil

        do {
            let _: ResendVerificationResponse = try await APIClient.shared.request(
                .resendVerificationEmail, body: nil
            )
            showingVerificationSentAlert = true
        } catch let apiError as APIError {
            verificationError = apiError.localizedDescription
        } catch {
            verificationError = "E-Mail konnte nicht gesendet werden"
        }

        isResendingVerification = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
