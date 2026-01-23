import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var showingLogoutAlert = false
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
                            ProfilePictureView(member: user, size: 60)

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

                    // Appearance section
                    Section(header: Text("Darstellung")) {
                        Picker(selection: $appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Label(theme.displayName, systemImage: theme.iconName)
                                    .tag(theme)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                    .foregroundColor(.green)
                                Text("Erscheinungsbild")
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

                // Logout section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Abmelden")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profil")
            .alert("Abmelden?", isPresented: $showingLogoutAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Abmelden", role: .destructive) {
                    // Dismiss sheet first for instant feedback
                    dismiss()
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
