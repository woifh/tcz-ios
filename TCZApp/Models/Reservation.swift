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

    var canCancel: Bool {
        !isShortNotice && status == "active"
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
