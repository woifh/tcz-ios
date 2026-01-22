import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    // Form fields
    @Published var firstname = ""
    @Published var lastname = ""
    @Published var email = ""
    @Published var street = ""
    @Published var city = ""
    @Published var zipCode = ""
    @Published var phone = ""

    // Password fields (only sent if user wants to change)
    @Published var password = ""
    @Published var confirmPassword = ""

    // Email notification preferences
    @Published var notificationsEnabled = true
    @Published var notifyOwnBookings = true
    @Published var notifyOtherBookings = true
    @Published var notifyCourtBlocked = true
    @Published var notifyBookingOverridden = true

    // Push notification preferences
    @Published var pushNotificationsEnabled = true
    @Published var pushNotifyOwnBookings = true
    @Published var pushNotifyOtherBookings = true
    @Published var pushNotifyCourtBlocked = true
    @Published var pushNotifyBookingOverridden = true

    // State management
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isConfirmingPayment = false
    @Published var isUploadingPicture = false
    @Published var error: String?
    @Published var successMessage: String?

    // Profile picture state
    @Published var hasProfilePicture = false
    @Published var profilePictureVersion = 0

    // Validation
    @Published var emailError: String?
    @Published var passwordError: String?

    private let apiClient: APIClientProtocol
    private var memberId: String?

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func initializeProfilePicture(from member: Member) {
        self.hasProfilePicture = member.hasProfilePicture ?? false
        self.profilePictureVersion = member.profilePictureVersion ?? 0
    }

    func loadProfile(memberId: String) async {
        self.memberId = memberId
        isLoading = true
        error = nil

        do {
            let member: Member = try await apiClient.request(.getMember(memberId: memberId), body: nil)
            self.firstname = member.firstname
            self.lastname = member.lastname
            self.email = member.email
            self.street = member.street ?? ""
            self.city = member.city ?? ""
            self.zipCode = member.zipCode ?? ""
            self.phone = member.phone ?? ""
            self.notificationsEnabled = member.notificationsEnabled ?? true
            self.notifyOwnBookings = member.notifyOwnBookings ?? true
            self.notifyOtherBookings = member.notifyOtherBookings ?? true
            self.notifyCourtBlocked = member.notifyCourtBlocked ?? true
            self.notifyBookingOverridden = member.notifyBookingOverridden ?? true
            self.pushNotificationsEnabled = member.pushNotificationsEnabled ?? true
            self.pushNotifyOwnBookings = member.pushNotifyOwnBookings ?? true
            self.pushNotifyOtherBookings = member.pushNotifyOtherBookings ?? true
            self.pushNotifyCourtBlocked = member.pushNotifyCourtBlocked ?? true
            self.pushNotifyBookingOverridden = member.pushNotifyBookingOverridden ?? true
            self.hasProfilePicture = member.hasProfilePicture ?? false
            self.profilePictureVersion = member.profilePictureVersion ?? 0
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Fehler beim Laden des Profils"
        }

        isLoading = false
    }

    func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            emailError = "Bitte geben Sie eine gültige E-Mail-Adresse ein"
            return false
        }
        emailError = nil
        return true
    }

    func validatePassword() -> Bool {
        // Only validate if user is trying to change password
        guard !password.isEmpty || !confirmPassword.isEmpty else {
            passwordError = nil
            return true
        }

        if password.count < 8 {
            passwordError = "Das Passwort muss mindestens 8 Zeichen haben"
            return false
        }

        if password != confirmPassword {
            passwordError = "Die Passwörter stimmen nicht überein"
            return false
        }

        passwordError = nil
        return true
    }

    var canSave: Bool {
        !firstname.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastname.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isSaving
    }

    func updateProfile() async -> Member? {
        guard let memberId = memberId else {
            error = "Benutzer-ID fehlt"
            return nil
        }

        // Validate
        guard validateEmail(), validatePassword() else {
            return nil
        }

        isSaving = true
        error = nil
        successMessage = nil

        let request = ProfileUpdateRequest(
            firstname: firstname.trimmingCharacters(in: .whitespaces),
            lastname: lastname.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
            street: street.isEmpty ? nil : street.trimmingCharacters(in: .whitespaces),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
            zipCode: zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespaces),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
            password: password.isEmpty ? nil : password,
            notificationsEnabled: notificationsEnabled,
            notifyOwnBookings: notifyOwnBookings,
            notifyOtherBookings: notifyOtherBookings,
            notifyCourtBlocked: notifyCourtBlocked,
            notifyBookingOverridden: notifyBookingOverridden,
            pushNotificationsEnabled: pushNotificationsEnabled,
            pushNotifyOwnBookings: pushNotifyOwnBookings,
            pushNotifyOtherBookings: pushNotifyOtherBookings,
            pushNotifyCourtBlocked: pushNotifyCourtBlocked,
            pushNotifyBookingOverridden: pushNotifyBookingOverridden
        )

        do {
            let response: ProfileUpdateResponse = try await apiClient.request(
                .updateMember(memberId: memberId),
                body: request
            )

            // Clear password fields after successful update
            password = ""
            confirmPassword = ""

            successMessage = "Profil erfolgreich aktualisiert"
            isSaving = false
            return response.member

        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isSaving = false
            return nil
        } catch {
            self.error = "Fehler beim Speichern des Profils"
            isSaving = false
            return nil
        }
    }

    func confirmPayment() async -> Bool {
        isConfirmingPayment = true
        error = nil
        successMessage = nil

        do {
            let _: PaymentConfirmationResponse = try await apiClient.request(.confirmPayment, body: nil)
            successMessage = "Zahlungsbestätigung wurde angefordert"
            isConfirmingPayment = false
            return true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isConfirmingPayment = false
            return false
        } catch {
            self.error = "Fehler beim Anfordern der Zahlungsbestätigung"
            isConfirmingPayment = false
            return false
        }
    }

    // MARK: - Profile Picture

    /// Upload a profile picture from JPEG data.
    /// The view is responsible for converting UIImage to JPEG Data before calling this method.
    func uploadProfilePicture(imageData: Data) async -> Member? {
        guard let memberId = memberId else {
            error = "Benutzer-ID fehlt"
            return nil
        }

        guard !imageData.isEmpty else {
            error = "Bild konnte nicht verarbeitet werden"
            return nil
        }

        isUploadingPicture = true
        error = nil
        successMessage = nil

        do {
            let response = try await apiClient.uploadProfilePicture(memberId: memberId, imageData: imageData)

            // Update local state
            self.hasProfilePicture = response.hasProfilePicture ?? true
            self.profilePictureVersion = response.profilePictureVersion ?? (self.profilePictureVersion + 1)

            // Invalidate cache for this member
            ProfilePictureCache.shared.invalidate(memberId: memberId)

            // Reload profile to get updated member data
            let member: Member = try await apiClient.request(.getMember(memberId: memberId), body: nil)

            successMessage = "Profilbild erfolgreich hochgeladen"
            isUploadingPicture = false
            return member

        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isUploadingPicture = false
            return nil
        } catch {
            self.error = "Fehler beim Hochladen des Profilbilds"
            isUploadingPicture = false
            return nil
        }
    }

    func deleteProfilePicture() async -> Member? {
        guard let memberId = memberId else {
            error = "Benutzer-ID fehlt"
            return nil
        }

        isUploadingPicture = true
        error = nil
        successMessage = nil

        do {
            try await apiClient.deleteProfilePicture(memberId: memberId)

            // Update local state
            self.hasProfilePicture = false

            // Invalidate cache for this member
            ProfilePictureCache.shared.invalidate(memberId: memberId)

            // Reload profile to get updated member data
            let member: Member = try await apiClient.request(.getMember(memberId: memberId), body: nil)

            successMessage = "Profilbild erfolgreich entfernt"
            isUploadingPicture = false
            return member

        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isUploadingPicture = false
            return nil
        } catch {
            self.error = "Fehler beim Entfernen des Profilbilds"
            isUploadingPicture = false
            return nil
        }
    }
}
