import Foundation

struct AvailabilityResponse: Codable {
    let date: String
    let grid: [CourtAvailability]
    let metadata: AvailabilityMetadata?
}

struct CourtAvailability: Codable, Identifiable {
    let courtId: Int
    let courtNumber: Int
    let slots: [TimeSlot]

    var id: Int { courtId }

    enum CodingKeys: String, CodingKey {
        case courtId = "court_id"
        case courtNumber = "court_number"
        case slots
    }
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
}

struct SlotDetails: Codable {
    // For reservations
    let bookedFor: String?
    let bookedForId: String?
    let bookedBy: String?
    let bookedById: String?
    let reservationId: Int?
    let isShortNotice: Bool?

    // For blocks
    let reason: String?
    let details: String?
    let blockId: Int?

    enum CodingKeys: String, CodingKey {
        case bookedFor = "booked_for"
        case bookedForId = "booked_for_id"
        case bookedBy = "booked_by"
        case bookedById = "booked_by_id"
        case reservationId = "reservation_id"
        case isShortNotice = "is_short_notice"
        case reason, details
        case blockId = "block_id"
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
