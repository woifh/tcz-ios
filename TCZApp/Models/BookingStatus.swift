import Foundation

struct BookingStatusResponse: Codable {
    let currentTime: String
    let userId: String
    let limits: BookingLimits
    let activeReservations: ActiveReservationCounts
    let nextReservations: [ReservationSummary]?

    enum CodingKeys: String, CodingKey {
        case currentTime = "current_time"
        case userId = "user_id"
        case limits
        case activeReservations = "active_reservations"
        case nextReservations = "next_reservations"
    }
}

struct BookingLimits: Codable {
    let regularReservations: LimitInfo
    let shortNoticeBookings: LimitInfo

    enum CodingKeys: String, CodingKey {
        case regularReservations = "regular_reservations"
        case shortNoticeBookings = "short_notice_bookings"
    }
}

struct LimitInfo: Codable {
    let limit: Int
    let current: Int
    let available: Int
    let canBook: Bool

    enum CodingKeys: String, CodingKey {
        case limit, current, available
        case canBook = "can_book"
    }
}

struct ActiveReservationCounts: Codable {
    let total: Int
    let regular: Int
    let shortNotice: Int

    enum CodingKeys: String, CodingKey {
        case total, regular
        case shortNotice = "short_notice"
    }
}

struct ReservationSummary: Codable, Identifiable {
    let id: Int
    let courtNumber: Int
    let date: String
    let startTime: String
    let endTime: String
    let isShortNotice: Bool

    var timeRange: String {
        "\(startTime) - \(endTime)"
    }

    var formattedDate: String {
        let parts = date.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[2]).\(parts[1]).\(parts[0])"
        }
        return date
    }

    enum CodingKeys: String, CodingKey {
        case id
        case courtNumber = "court_number"
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case isShortNotice = "is_short_notice"
    }
}
