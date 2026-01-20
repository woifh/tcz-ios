import Foundation

struct Reservation: Codable, Identifiable, Equatable {
    let id: Int
    let courtId: Int
    let courtNumber: Int?
    let date: String
    let startTime: String
    let endTime: String
    let bookedFor: String?
    let bookedForId: String
    let bookedBy: String?
    let bookedById: String
    let status: String
    let isShortNotice: Bool
    let isActive: Bool?
    let bookingStatus: String?
    let reason: String?

    var canCancel: Bool {
        // Short-notice bookings can never be cancelled
        if isShortNotice {
            return false
        }

        // Check time-based rules
        if isSuspended {
            // Suspended: can cancel if not in the past (future OR currently happening)
            return !isInPast
        } else if status == "active" {
            // Active: can cancel until 15 minutes before start
            return isMoreThan15MinutesAway
        }

        return false
    }

    var isSuspended: Bool {
        status == "suspended"
    }

    /// Returns true if the reservation's start time has already passed
    var isInPast: Bool {
        guard let reservationStart = startDateTime else { return true }
        return Date() >= reservationStart
    }

    /// Returns true if there's more than 15 minutes until the reservation starts
    private var isMoreThan15MinutesAway: Bool {
        guard let reservationStart = startDateTime else { return false }
        let fifteenMinutesFromNow = Date().addingTimeInterval(15 * 60)
        return reservationStart > fifteenMinutesFromNow
    }

    /// Parses date + startTime into a Date object (Europe/Berlin timezone)
    private var startDateTime: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        return dateFormatter.date(from: "\(date) \(startTime)")
    }

    var timeRange: String {
        "\(startTime) - \(endTime)"
    }

    var formattedDate: String {
        // Convert from YYYY-MM-DD to DD.MM.YYYY
        let parts = date.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[2]).\(parts[1]).\(parts[0])"
        }
        return date
    }

    enum CodingKeys: String, CodingKey {
        case id
        case courtId = "court_id"
        case courtNumber = "court_number"
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case bookedFor = "booked_for"
        case bookedForId = "booked_for_id"
        case bookedBy = "booked_by"
        case bookedById = "booked_by_id"
        case status
        case isShortNotice = "is_short_notice"
        case isActive = "is_active"
        case bookingStatus = "booking_status"
        case reason
    }

    static func == (lhs: Reservation, rhs: Reservation) -> Bool {
        lhs.id == rhs.id
    }
}

// Response from reservations list endpoint
struct ReservationsResponse: Decodable {
    let currentTime: String?
    let reservations: [Reservation]
    let statistics: ReservationStatistics?

    enum CodingKeys: String, CodingKey {
        case currentTime = "current_time"
        case reservations
        case statistics
    }
}

struct ReservationStatistics: Decodable {
    let totalCount: Int
    let activeCount: Int
    let pastCount: Int?
    let regularActiveCount: Int?
    let shortNoticeActiveCount: Int?

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case activeCount = "active_count"
        case pastCount = "past_count"
        case regularActiveCount = "regular_active_count"
        case shortNoticeActiveCount = "short_notice_active_count"
    }
}

// Create booking request
struct CreateBookingRequest: Encodable {
    let courtId: Int
    let date: String
    let startTime: String
    let bookedForId: String

    enum CodingKeys: String, CodingKey {
        case courtId = "court_id"
        case date
        case startTime = "start_time"
        case bookedForId = "booked_for_id"
    }
}

// Create booking response
struct BookingCreatedResponse: Decodable {
    let message: String
    let reservation: CreatedReservationInfo?
}

struct CreatedReservationInfo: Decodable {
    let id: Int
    let courtId: Int
    let courtNumber: Int?
    let date: String
    let startTime: String
    let endTime: String
    let isShortNotice: Bool
    let bookedFor: String?
    let bookedForId: String?
    let bookedById: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case courtId = "court_id"
        case courtNumber = "court_number"
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case isShortNotice = "is_short_notice"
        case bookedFor = "booked_for"
        case bookedForId = "booked_for_id"
        case bookedById = "booked_by_id"
        case status
    }
}

// Cancel response
struct CancelResponse: Decodable {
    let message: String
}
