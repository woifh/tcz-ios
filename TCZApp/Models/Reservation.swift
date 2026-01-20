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
    let bookedForHasProfilePicture: Bool?
    let bookedForProfilePictureVersion: Int?
    let bookedBy: String?
    let bookedById: String
    let status: String
    let isShortNotice: Bool
    let isActive: Bool?
    let bookingStatus: String?
    let reason: String?
    let canCancel: Bool

    var isSuspended: Bool {
        status == "suspended"
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
        case bookedForHasProfilePicture = "booked_for_has_profile_picture"
        case bookedForProfilePictureVersion = "booked_for_profile_picture_version"
        case bookedBy = "booked_by"
        case bookedById = "booked_by_id"
        case status
        case isShortNotice = "is_short_notice"
        case isActive = "is_active"
        case bookingStatus = "booking_status"
        case reason
        case canCancel = "can_cancel"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        courtId = try container.decode(Int.self, forKey: .courtId)
        courtNumber = try container.decodeIfPresent(Int.self, forKey: .courtNumber)
        date = try container.decode(String.self, forKey: .date)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        bookedFor = try container.decodeIfPresent(String.self, forKey: .bookedFor)
        bookedForId = try container.decode(String.self, forKey: .bookedForId)
        bookedForHasProfilePicture = try container.decodeIfPresent(Bool.self, forKey: .bookedForHasProfilePicture)
        bookedForProfilePictureVersion = try container.decodeIfPresent(Int.self, forKey: .bookedForProfilePictureVersion)
        bookedBy = try container.decodeIfPresent(String.self, forKey: .bookedBy)
        bookedById = try container.decode(String.self, forKey: .bookedById)
        status = try container.decode(String.self, forKey: .status)
        isShortNotice = try container.decode(Bool.self, forKey: .isShortNotice)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        bookingStatus = try container.decodeIfPresent(String.self, forKey: .bookingStatus)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        canCancel = try container.decodeIfPresent(Bool.self, forKey: .canCancel) ?? false
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
