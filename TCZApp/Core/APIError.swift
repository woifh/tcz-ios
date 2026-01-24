import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case unauthorized
    case forbidden(String)
    case notFound(String?)
    case badRequest(String)
    case bookingLimitExceeded(String, [ActiveSession])
    case rateLimited(String?)
    case serverError(Int, String?)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Ungueltige Antwort vom Server"
        case .invalidData:
            return "Fehler beim Erstellen der Anfragedaten"
        case .unauthorized:
            return "Bitte melde dich erneut an"
        case .forbidden(let message):
            return message
        case .notFound(let message):
            return message ?? "Die angeforderte Ressource wurde nicht gefunden"
        case .badRequest(let message):
            return message
        case .bookingLimitExceeded(let message, _):
            return message
        case .rateLimited(let message):
            return message ?? "Zu viele Anfragen. Bitte warte einen Moment."
        case .serverError(let code, let message):
            return message ?? "Serverfehler (\(code)). Bitte versuche es später erneut."
        case .networkError:
            return "Netzwerkfehler. Bitte überprüfe deine Verbindung."
        case .decodingError:
            return "Fehler beim Verarbeiten der Daten"
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String
    let activeSessions: [ActiveSession]?

    enum CodingKeys: String, CodingKey {
        case error
        case activeSessions = "active_sessions"
    }

    /// Returns a full error message including active session details if available
    var fullErrorMessage: String {
        guard let sessions = activeSessions, !sessions.isEmpty else {
            return error
        }

        let sessionLines = sessions.map { "• \($0.formattedDescription)" }
        return error + "\n" + sessionLines.joined(separator: "\n")
    }
}

struct ActiveSession: Decodable, Identifiable {
    let reservationId: Int
    let date: String
    let startTime: String
    let courtNumber: Int?
    let bookedById: String?
    let bookedByName: String?
    let isShortNotice: Bool?

    var id: Int { reservationId }

    enum CodingKeys: String, CodingKey {
        case reservationId = "reservation_id"
        case date
        case startTime = "start_time"
        case courtNumber = "court_number"
        case bookedById = "booked_by_id"
        case bookedByName = "booked_by_name"
        case isShortNotice = "is_short_notice"
    }

    var formattedDescription: String {
        let dateParts = date.split(separator: "-")
        let dateStr = dateParts.count == 3 ? "\(dateParts[2]).\(dateParts[1])." : date

        let startHour = Int(startTime.prefix(2)) ?? 0
        let endTime = String(format: "%02d:00", startHour + 1)
        let courtStr = courtNumber.map { "Platz \($0)" } ?? ""

        return "\(dateStr) \(startTime)-\(endTime) \(courtStr)"
    }

    /// Formatted date for display (e.g., "25.01.2026")
    var formattedDate: String {
        let dateParts = date.split(separator: "-")
        return dateParts.count == 3 ? "\(dateParts[2]).\(dateParts[1]).\(dateParts[0])" : date
    }

    /// Time range string (e.g., "10:00-11:00")
    var timeRange: String {
        let startHour = Int(startTime.prefix(2)) ?? 0
        let endTime = String(format: "%02d:00", startHour + 1)
        return "\(startTime)-\(endTime)"
    }

    /// Court display name (e.g., "Platz 2")
    var courtName: String {
        courtNumber.map { "Platz \($0)" } ?? "Platz"
    }
}
