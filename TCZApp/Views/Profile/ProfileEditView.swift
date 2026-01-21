import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var pushService: PushNotificationService
    @Environment(\.dismiss) private var dismiss

    // Photo picker state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        mainContent
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { loadingOverlay }
            .task { await loadProfileTask() }
            .interactiveDismissDisabled(viewModel.isSaving || viewModel.isUploadingPicture)
            .onChange(of: selectedPhotoItem) { newItem in
                Task { await handlePhotoSelection(newItem) }
            }
            .alert("Profilbild entfernen", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Entfernen", role: .destructive) { deleteProfilePicture() }
            } message: {
                Text("Möchtest du dein Profilbild wirklich entfernen?")
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            ProgressView("Lade Profil...")
        } else {
            formContent
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Speichern") { saveProfile() }
                .disabled(!viewModel.canSave || viewModel.isLoading)
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isSaving || viewModel.isUploadingPicture {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }

    private func loadProfileTask() async {
        if let userId = authViewModel.currentUser?.id {
            await viewModel.loadProfile(memberId: userId)
        }
    }

    private var formContent: some View {
        Form {
            profilePictureSection
            personalInfoSection
            contactSection
            addressSection
            passwordSection
            notificationsSection
            pushNotificationsSection
            messagesSection
        }
    }

    private var profilePictureSection: some View {
        Section(header: Text("Profilbild")) {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    profilePictureDisplay
                    profilePictureButtons
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var profilePictureDisplay: some View {
        if let user = authViewModel.currentUser {
            ProfilePictureView(
                memberId: user.id,
                hasProfilePicture: viewModel.hasProfilePicture,
                profilePictureVersion: viewModel.profilePictureVersion,
                name: user.name,
                size: 100
            )
        } else {
            ProfilePictureView(
                memberId: nil,
                hasProfilePicture: false,
                profilePictureVersion: 0,
                name: "\(viewModel.firstname) \(viewModel.lastname)",
                size: 100
            )
        }
    }

    private var profilePictureButtons: some View {
        let hasPicture = viewModel.hasProfilePicture
        return HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: hasPicture ? "pencil" : "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.bordered)
            .tint(.gray)

            if hasPicture {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
        }
    }

    private var personalInfoSection: some View {
        Section(header: Text("Persönliche Daten")) {
            TextField("Vorname", text: $viewModel.firstname)
                .textContentType(.givenName)
            TextField("Nachname", text: $viewModel.lastname)
                .textContentType(.familyName)
        }
    }

    private var contactSection: some View {
        Section(header: Text("Kontakt")) {
            emailRow
            emailErrorRow
            phoneRow
        }
    }

    private var emailRow: some View {
        HStack {
            TextField("E-Mail", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            if let emailVerified = authViewModel.currentUser?.emailVerified {
                Image(systemName: emailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(emailVerified ? .green : .orange)
            }
        }
    }

    @ViewBuilder
    private var emailErrorRow: some View {
        if let emailError = viewModel.emailError {
            Text(emailError)
                .foregroundColor(.red)
                .font(.caption)
        }
    }

    private var phoneRow: some View {
        TextField("Telefon", text: $viewModel.phone)
            .textContentType(.telephoneNumber)
            .keyboardType(.phonePad)
    }

    private var addressSection: some View {
        Section(header: Text("Adresse")) {
            TextField("Strasse", text: $viewModel.street)
                .textContentType(.streetAddressLine1)
            TextField("PLZ", text: $viewModel.zipCode)
                .textContentType(.postalCode)
                .keyboardType(.numberPad)
            TextField("Ort", text: $viewModel.city)
                .textContentType(.addressCity)
        }
    }

    private var passwordSection: some View {
        Section(header: Text("Passwort ändern"), footer: Text("Lass die Felder leer, wenn du das Passwort nicht ändern möchtest.")) {
            SecureField("Neues Passwort", text: $viewModel.password)
                .textContentType(.newPassword)
            SecureField("Passwort bestätigen", text: $viewModel.confirmPassword)
                .textContentType(.newPassword)
            passwordErrorRow
        }
    }

    @ViewBuilder
    private var passwordErrorRow: some View {
        if let passwordError = viewModel.passwordError {
            Text(passwordError)
                .foregroundColor(.red)
                .font(.caption)
        }
    }

    private var notificationsSection: some View {
        Section(header: Text("E-Mail Benachrichtigungen")) {
            Toggle("Benachrichtigungen aktiviert", isOn: $viewModel.notificationsEnabled)
            notificationToggles
        }
    }

    @ViewBuilder
    private var notificationToggles: some View {
        if viewModel.notificationsEnabled {
            Toggle("Eigene Buchungen", isOn: $viewModel.notifyOwnBookings)
            Toggle("Buchungen anderer", isOn: $viewModel.notifyOtherBookings)
            Toggle("Platz gesperrt", isOn: $viewModel.notifyCourtBlocked)
            Toggle("Buchung ueberschrieben", isOn: $viewModel.notifyBookingOverridden)
        }
    }

    private var pushNotificationsSection: some View {
        Section(header: Text("Push-Benachrichtigungen")) {
            if pushService.authorizationStatus == .denied {
                HStack {
                    Text("Push deaktiviert")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Einstellungen") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote)
                }
            } else if pushService.authorizationStatus == .notDetermined {
                Button("Push-Benachrichtigungen aktivieren") {
                    Task {
                        await pushService.requestAuthorization()
                    }
                }
            } else {
                Toggle("Push aktiviert", isOn: $viewModel.pushNotificationsEnabled)
                pushNotificationToggles
            }
        }
    }

    @ViewBuilder
    private var pushNotificationToggles: some View {
        if viewModel.pushNotificationsEnabled {
            Toggle("Eigene Buchungen", isOn: $viewModel.pushNotifyOwnBookings)
            Toggle("Buchungen fuer dich", isOn: $viewModel.pushNotifyOtherBookings)
            Toggle("Platz gesperrt", isOn: $viewModel.pushNotifyCourtBlocked)
            Toggle("Buchung ueberschrieben", isOn: $viewModel.pushNotifyBookingOverridden)
        }
    }

    @ViewBuilder
    private var messagesSection: some View {
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

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            // Load the image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }

            // Convert to JPEG data in the View layer (keeps UIKit out of ViewModel)
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.9) else {
                return
            }

            // Upload the image
            if let updatedMember = await viewModel.uploadProfilePicture(imageData: jpegData) {
                authViewModel.updateCurrentUser(updatedMember)
            }

            // Clear selection to allow re-selecting same image
            selectedPhotoItem = nil
        } catch {
            #if DEBUG
            print("Error loading photo: \(error)")
            #endif
        }
    }

    private func deleteProfilePicture() {
        Task {
            if let updatedMember = await viewModel.deleteProfilePicture() {
                authViewModel.updateCurrentUser(updatedMember)
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
