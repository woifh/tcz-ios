import Foundation

struct AvailabilityResponse: Codable {
    let date: String
    let currentHour: Int?
    let courts: [CourtAvailability]
    let metadata: AvailabilityMetadata?

    enum CodingKeys: String, CodingKey {
        case date
        case currentHour = "current_hour"
        case courts
        case metadata
    }
}

struct CourtAvailability: Codable, Identifiable {
    let courtId: Int
    let courtNumber: Int
    let occupied: [OccupiedSlot]

    var id: Int { courtId }

    enum CodingKeys: String, CodingKey {
        case courtId = "court_id"
        case courtNumber = "court_number"
        case occupied
    }
}

struct OccupiedSlot: Codable {
    let time: String
    let status: SlotStatus
    let details: SlotDetails?
}

struct TimeSlot: Codable, Identifiable {
    let time: String
    let status: SlotStatus
    let details: SlotDetails?

    var id: String { time }
}

enum SlotStatus: String, Codable {
    case available
    case reserved
    case shortNotice = "short_notice"
    case blocked
    case blockedTemporary = "blocked_temporary"
}

struct SuspendedReservation: Codable {
    let bookedFor: String
    let bookedForId: String
    let reservationId: Int

    enum CodingKeys: String, CodingKey {
        case bookedFor = "booked_for"
        case bookedForId = "booked_for_id"
        case reservationId = "reservation_id"
    }
}

struct SlotDetails: Codable {
    // For reservations
    let bookedFor: String?
    let bookedForId: String?
    let bookedBy: String?
    let bookedById: String?
    let reservationId: Int?
    let isShortNotice: Bool?
    let canCancel: Bool?

    // For blocks
    let reason: String?
    let details: String?
    let blockId: Int?

    // For temporary blocks
    let isTemporary: Bool?
    let suspendedReservation: SuspendedReservation?

    enum CodingKeys: String, CodingKey {
        case bookedFor = "booked_for"
        case bookedForId = "booked_for_id"
        case bookedBy = "booked_by"
        case bookedById = "booked_by_id"
        case reservationId = "reservation_id"
        case isShortNotice = "is_short_notice"
        case canCancel = "can_cancel"
        case reason, details
        case blockId = "block_id"
        case isTemporary = "is_temporary"
        case suspendedReservation = "suspended_reservation"
    }
}

struct AvailabilityMetadata: Codable {
    let generatedAt: String?
    let usesRealtimeLogic: Bool?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case usesRealtimeLogic = "uses_realtime_logic"
        case timezone
    }
}

// MARK: - Range API Response Models

/// Response from /api/courts/availability/range endpoint
struct AvailabilityRangeResponse: Codable {
    let range: AvailabilityRange
    let days: [String: DayAvailability]
    let metadata: AvailabilityRangeMetadata
}

/// Range information from the response
struct AvailabilityRange: Codable {
    let start: String
    let end: String
    let daysRequested: Int

    enum CodingKeys: String, CodingKey {
        case start, end
        case daysRequested = "days_requested"
    }
}

/// Single day availability within a range response
struct DayAvailability: Codable {
    let currentHour: Int?
    let courts: [CourtAvailability]

    enum CodingKeys: String, CodingKey {
        case currentHour = "current_hour"
        case courts
    }
}

/// Metadata for range response with cache hint
struct AvailabilityRangeMetadata: Codable {
    let generatedAt: String?
    let timezone: String?
    let cacheHintSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case timezone
        case cacheHintSeconds = "cache_hint_seconds"
    }
}
