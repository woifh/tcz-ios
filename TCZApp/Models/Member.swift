import Foundation

struct Member: Codable, Identifiable, Equatable {
    let id: Int
    let firstname: String
    let lastname: String
    let email: String
    let name: String

    static func == (lhs: Member, rhs: Member) -> Bool {
        lhs.id == rhs.id
    }
}

struct MemberSummary: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let email: String

    static func == (lhs: MemberSummary, rhs: MemberSummary) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Login response
struct LoginResponse: Decodable {
    let user: Member
}

// Favorites response
struct FavoritesResponse: Decodable {
    let favourites: [MemberSummary]
}

// Search response
struct SearchResponse: Decodable {
    let results: [MemberSummary]
}
