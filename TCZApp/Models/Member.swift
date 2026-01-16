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

    enum CodingKeys: String, CodingKey {
        case id, firstname, lastname, email, name, street, city, phone
        case zipCode = "zip_code"
        case notificationsEnabled = "notifications_enabled"
        case notifyOwnBookings = "notify_own_bookings"
        case notifyOtherBookings = "notify_other_bookings"
        case notifyCourtBlocked = "notify_court_blocked"
        case notifyBookingOverridden = "notify_booking_overridden"
    }

    static func == (lhs: Member, rhs: Member) -> Bool {
        lhs.id == rhs.id
    }
}

struct MemberSummary: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let email: String

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

    enum CodingKeys: String, CodingKey {
        case firstname, lastname, email, street, city, phone, password
        case zipCode = "zip_code"
        case notificationsEnabled = "notifications_enabled"
        case notifyOwnBookings = "notify_own_bookings"
        case notifyOtherBookings = "notify_other_bookings"
        case notifyCourtBlocked = "notify_court_blocked"
        case notifyBookingOverridden = "notify_booking_overridden"
    }
}

// Profile update response
struct ProfileUpdateResponse: Decodable {
    let message: String
    let member: Member
}
