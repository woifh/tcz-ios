import Foundation

enum APIEndpoint {
    case login
    case logout
    case availability(date: String)
    case reservations
    case reservationStatus
    case createReservation
    case cancelReservation(id: Int)
    case searchMembers(query: String)
    case favorites(memberId: String)
    case addFavorite(memberId: String)
    case removeFavorite(memberId: String, favoriteId: String)

    var path: String {
        switch self {
        case .login:
            return "/auth/login/api"
        case .logout:
            return "/auth/logout"
        case .availability(let date):
            return "/api/courts/availability?date=\(date)"
        case .reservations:
            return "/api/reservations/"
        case .reservationStatus:
            return "/api/reservations/status"
        case .createReservation:
            return "/api/reservations/"
        case .cancelReservation(let id):
            return "/api/reservations/\(id)"
        case .searchMembers(let query):
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/api/members/search?q=\(encoded)"
        case .favorites(let memberId):
            return "/api/members/\(memberId)/favourites"
        case .addFavorite(let memberId):
            return "/api/members/\(memberId)/favourites"
        case .removeFavorite(let memberId, let favoriteId):
            return "/api/members/\(memberId)/favourites/\(favoriteId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createReservation, .addFavorite:
            return .post
        case .logout, .availability, .reservations, .reservationStatus,
             .searchMembers, .favorites:
            return .get
        case .cancelReservation, .removeFavorite:
            return .delete
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
