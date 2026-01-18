import SwiftUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Lade Profil...")
            } else {
                formContent
            }
        }
        .navigationTitle("Profil bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    saveProfile()
                }
                .disabled(!viewModel.canSave || viewModel.isLoading)
            }
        }
        .overlay(
            Group {
                if viewModel.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        )
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadProfile(memberId: userId)
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    private var formContent: some View {
        Form {
            // Personal Information Section
            Section(header: Text("Persönliche Daten")) {
                TextField("Vorname", text: $viewModel.firstname)
                    .textContentType(.givenName)

                TextField("Nachname", text: $viewModel.lastname)
                    .textContentType(.familyName)
            }

            // Contact Section
            Section(header: Text("Kontakt")) {
                TextField("E-Mail", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                if let emailError = viewModel.emailError {
                    Text(emailError)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                TextField("Telefon", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            // Address Section
            Section(header: Text("Adresse")) {
                TextField("Strasse", text: $viewModel.street)
                    .textContentType(.streetAddressLine1)

                TextField("PLZ", text: $viewModel.zipCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numberPad)

                TextField("Ort", text: $viewModel.city)
                    .textContentType(.addressCity)
            }

            // Password Section
            Section(header: Text("Passwort ändern"), footer: Text("Lass die Felder leer, wenn du das Passwort nicht ändern möchtest.")) {
                SecureField("Neues Passwort", text: $viewModel.password)
                    .textContentType(.newPassword)

                SecureField("Passwort bestätigen", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)

                if let passwordError = viewModel.passwordError {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Notifications Section
            Section(header: Text("E-Mail Benachrichtigungen")) {
                Toggle("Benachrichtigungen aktiviert", isOn: $viewModel.notificationsEnabled)

                if viewModel.notificationsEnabled {
                    Toggle("Eigene Buchungen", isOn: $viewModel.notifyOwnBookings)
                    Toggle("Buchungen anderer", isOn: $viewModel.notifyOtherBookings)
                    Toggle("Platz gesperrt", isOn: $viewModel.notifyCourtBlocked)
                    Toggle("Buchung ueberschrieben", isOn: $viewModel.notifyBookingOverridden)
                }
            }

            // Error/Success Messages
            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            if let success = viewModel.successMessage {
                Section {
                    Text(success)
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func saveProfile() {
        Task {
            if let updatedMember = await viewModel.updateProfile() {
                // Update AuthViewModel with new user data
                authViewModel.updateCurrentUser(updatedMember)

                // Dismiss after short delay to show success message
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileEditView()
            .environmentObject(AuthViewModel())
    }
}
