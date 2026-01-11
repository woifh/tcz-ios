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
    case favorites(memberId: Int)
    case addFavorite(memberId: Int)
    case removeFavorite(memberId: Int, favoriteId: Int)

    var path: String {
        switch self {
        case .login:
            return "/auth/login/api"
        case .logout:
            return "/auth/logout"
        case .availability(let date):
            return "/courts/availability?date=\(date)"
        case .reservations:
            return "/reservations/?format=json"
        case .reservationStatus:
            return "/reservations/status"
        case .createReservation:
            return "/reservations/"
        case .cancelReservation(let id):
            return "/reservations/\(id)"
        case .searchMembers(let query):
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/members/search?q=\(encoded)"
        case .favorites(let memberId):
            return "/members/\(memberId)/favourites"
        case .addFavorite(let memberId):
            return "/members/\(memberId)/favourites"
        case .removeFavorite(let memberId, let favoriteId):
            return "/members/\(memberId)/favourites/\(favoriteId)"
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
