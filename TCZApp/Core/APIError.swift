import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case unauthorized
    case forbidden(String)
    case notFound(String?)
    case badRequest(String)
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

struct ActiveSession: Decodable {
    let date: String
    let startTime: String
    let courtNumber: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case startTime = "start_time"
        case courtNumber = "court_number"
    }

    var formattedDescription: String {
        let dateParts = date.split(separator: "-")
        let dateStr = dateParts.count == 3 ? "\(dateParts[2]).\(dateParts[1])." : date

        let startHour = Int(startTime.prefix(2)) ?? 0
        let endTime = String(format: "%02d:00", startHour + 1)
        let courtStr = courtNumber.map { "Platz \($0)" } ?? ""

        return "\(dateStr) \(startTime)-\(endTime) \(courtStr)"
    }
}
