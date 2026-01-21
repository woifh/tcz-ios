import Foundation

struct Member: Codable, Identifiable, Equatable {
    let id: String
    let firstname: String
    let lastname: String
    let email: String
    let name: String

    // Profile fields
    let street: String?
    let city: String?
    let zipCode: String?
    let phone: String?
    let notificationsEnabled: Bool?
    let notifyOwnBookings: Bool?
    let notifyOtherBookings: Bool?
    let notifyCourtBlocked: Bool?
    let notifyBookingOverridden: Bool?
    let pushNotificationsEnabled: Bool?
    let pushNotifyOwnBookings: Bool?
    let pushNotifyOtherBookings: Bool?
    let pushNotifyCourtBlocked: Bool?
    let pushNotifyBookingOverridden: Bool?

    // Email verification
    let emailVerified: Bool?

    // Profile picture
    let hasProfilePicture: Bool?
    let profilePictureVersion: Int?

    // Payment status fields
    let feePaid: Bool?
    let paymentConfirmationRequested: Bool?
    let paymentConfirmationRequestedAt: String?

    // Role/membership fields
    let role: String?
    let membershipType: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, firstname, lastname, email, name, street, city, phone, role
        case zipCode = "zip_code"
        case notificationsEnabled = "notifications_enabled"
        case notifyOwnBookings = "notify_own_bookings"
        case notifyOtherBookings = "notify_other_bookings"
        case notifyCourtBlocked = "notify_court_blocked"
        case notifyBookingOverridden = "notify_booking_overridden"
        case pushNotificationsEnabled = "push_notifications_enabled"
        case pushNotifyOwnBookings = "push_notify_own_bookings"
        case pushNotifyOtherBookings = "push_notify_other_bookings"
        case pushNotifyCourtBlocked = "push_notify_court_blocked"
        case pushNotifyBookingOverridden = "push_notify_booking_overridden"
        case emailVerified = "email_verified"
        case hasProfilePicture = "has_profile_picture"
        case profilePictureVersion = "profile_picture_version"
        case feePaid = "fee_paid"
        case paymentConfirmationRequested = "payment_confirmation_requested"
        case paymentConfirmationRequestedAt = "payment_confirmation_requested_at"
        case membershipType = "membership_type"
        case isActive = "is_active"
    }

    // MARK: - Presentation Helpers
    // Note: These computed properties are presentation logic for determining what UI elements to show.
    // While they could be moved to ViewModels, they're kept here for convenience since they depend
    // only on model properties and have no side effects. Consider moving to ViewModels if the
    // logic becomes more complex or requires external dependencies.

    /// Returns true if the payment reminder banner should be shown.
    /// Shows when: fee is not paid AND no confirmation request is pending.
    var shouldShowPaymentReminder: Bool {
        guard let feePaid = feePaid else { return false }
        if feePaid { return false }
        return !(paymentConfirmationRequested ?? false)
    }

    /// Returns true if a payment confirmation has been requested but not yet processed.
    /// Shows when: fee is not paid AND confirmation has been requested.
    var hasPendingPaymentConfirmation: Bool {
        guard let feePaid = feePaid, !feePaid else { return false }
        return paymentConfirmationRequested ?? false
    }

    /// Returns true if the email verification reminder should be shown.
    /// Shows when: email is explicitly marked as not verified.
    var shouldShowEmailVerificationReminder: Bool {
        guard let verified = emailVerified else { return false }
        return !verified
    }

    static func == (lhs: Member, rhs: Member) -> Bool {
        lhs.id == rhs.id
    }
}

struct MemberSummary: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let email: String
    let hasProfilePicture: Bool?
    let profilePictureVersion: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case hasProfilePicture = "has_profile_picture"
        case profilePictureVersion = "profile_picture_version"
    }

    static func == (lhs: MemberSummary, rhs: MemberSummary) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Login response
struct LoginResponse: Decodable {
    let user: Member
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
    }
}

// Favorites response
struct FavoritesResponse: Decodable {
    let favourites: [MemberSummary]
}

// Search response
struct SearchResponse: Decodable {
    let results: [MemberSummary]
}

// Add favorite request
struct AddFavoriteRequest: Encodable {
    let favouriteId: String

    enum CodingKeys: String, CodingKey {
        case favouriteId = "favourite_id"
    }
}

// Add favorite response
struct AddFavoriteResponse: Decodable {
    let message: String
    let favourite: MemberSummary
}

// Profile update request
struct ProfileUpdateRequest: Encodable {
    let firstname: String
    let lastname: String
    let email: String
    let street: String?
    let city: String?
    let zipCode: String?
    let phone: String?
    let password: String?
    let notificationsEnabled: Bool
    let notifyOwnBookings: Bool
    let notifyOtherBookings: Bool
    let notifyCourtBlocked: Bool
    let notifyBookingOverridden: Bool
    let pushNotificationsEnabled: Bool
    let pushNotifyOwnBookings: Bool
    let pushNotifyOtherBookings: Bool
    let pushNotifyCourtBlocked: Bool
    let pushNotifyBookingOverridden: Bool

    enum CodingKeys: String, CodingKey {
        case firstname, lastname, email, street, city, phone, password
        case zipCode = "zip_code"
        case notificationsEnabled = "notifications_enabled"
        case notifyOwnBookings = "notify_own_bookings"
        case notifyOtherBookings = "notify_other_bookings"
        case notifyCourtBlocked = "notify_court_blocked"
        case notifyBookingOverridden = "notify_booking_overridden"
        case pushNotificationsEnabled = "push_notifications_enabled"
        case pushNotifyOwnBookings = "push_notify_own_bookings"
        case pushNotifyOtherBookings = "push_notify_other_bookings"
        case pushNotifyCourtBlocked = "push_notify_court_blocked"
        case pushNotifyBookingOverridden = "push_notify_booking_overridden"
    }
}

// Profile update response
struct ProfileUpdateResponse: Decodable {
    let message: String
    let member: Member
}

// Payment confirmation response
struct PaymentConfirmationResponse: Decodable {
    let message: String
    let paymentConfirmationRequested: Bool

    enum CodingKeys: String, CodingKey {
        case message
        case paymentConfirmationRequested = "payment_confirmation_requested"
    }
}

// Email verification response
struct ResendVerificationResponse: Decodable {
    let message: String
}

// Profile picture response
struct ProfilePictureResponse: Decodable {
    let message: String
    let hasProfilePicture: Bool?
    let profilePictureVersion: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case hasProfilePicture = "has_profile_picture"
        case profilePictureVersion = "profile_picture_version"
    }
}
