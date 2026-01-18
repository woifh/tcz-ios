import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden(String)
    case notFound
    case badRequest(String)
    case rateLimited
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Ungueltige Antwort vom Server"
        case .unauthorized:
            return "Bitte melde dich erneut an"
        case .forbidden(let message):
            return message
        case .notFound:
            return "Die angeforderte Ressource wurde nicht gefunden"
        case .badRequest(let message):
            return message
        case .rateLimited:
            return "Zu viele Anfragen. Bitte warte einen Moment."
        case .serverError(let code):
            return "Serverfehler (\(code)). Bitte versuche es später erneut."
        case .networkError:
            return "Netzwerkfehler. Bitte überprüfe deine Verbindung."
        case .decodingError:
            return "Fehler beim Verarbeiten der Daten"
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String
}
