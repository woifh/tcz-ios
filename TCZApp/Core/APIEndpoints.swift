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
    case serverVersion
    case serverChangelog
    case getMember(memberId: String)
    case updateMember(memberId: String)

    var path: String {
        switch self {
        case .login:
            return "/auth/login/api"
        case .logout:
            return "/auth/logout"
        case .serverVersion:
            return "/version"
        case .serverChangelog:
            return "/changelog"
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
        case .getMember(let memberId):
            return "/api/members/\(memberId)"
        case .updateMember(let memberId):
            return "/api/members/\(memberId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .createReservation, .addFavorite:
            return .post
        case .logout, .availability, .reservations, .reservationStatus,
             .searchMembers, .favorites, .serverVersion, .serverChangelog, .getMember:
            return .get
        case .cancelReservation, .removeFavorite:
            return .delete
        case .updateMember:
            return .put
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
