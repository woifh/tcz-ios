import Foundation

struct AddFavoriteRequest: Encodable {
    let favouriteId: Int

    enum CodingKeys: String, CodingKey {
        case favouriteId = "favourite_id"
    }
}

struct AddFavoriteResponse: Decodable {
    let message: String
    let favourite: MemberSummary
}

struct RemoveFavoriteResponse: Decodable {
    let message: String
}

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [MemberSummary] = []
    @Published var searchResults: [MemberSummary] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var isAdding = false
    @Published var error: String?
    @Published var searchQuery = ""

    private let apiClient: APIClientProtocol
    private(set) var currentUserId: Int?

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func setCurrentUserId(_ id: Int) {
        self.currentUserId = id
    }

    func loadFavorites() async {
        guard let userId = currentUserId else { return }

        isLoading = true
        error = nil

        do {
            let response: FavoritesResponse = try await apiClient.request(
                .favorites(memberId: userId), body: nil
            )
            favorites = response.favourites
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = "Fehler beim Laden der Favoriten"
        }

        isLoading = false
    }

    func searchMembers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            let response: SearchResponse = try await apiClient.request(
                .searchMembers(query: query), body: nil
            )
            // Filter out already favorited members and self
            let favoriteIds = Set(favorites.map { $0.id })
            searchResults = response.results.filter { member in
                member.id != currentUserId && !favoriteIds.contains(member.id)
            }
        } catch {
            searchResults = []
        }

        isSearching = false
    }

    func addFavorite(_ memberId: Int) async -> Bool {
        guard let userId = currentUserId else { return false }

        isAdding = true

        let request = AddFavoriteRequest(favouriteId: memberId)

        do {
            let response: AddFavoriteResponse = try await apiClient.request(
                .addFavorite(memberId: userId), body: request
            )
            favorites.append(response.favourite)
            searchResults.removeAll { $0.id == memberId }
            searchQuery = ""
            isAdding = false
            return true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            isAdding = false
            return false
        } catch {
            self.error = "Fehler beim Hinzufuegen"
            isAdding = false
            return false
        }
    }

    func removeFavorite(_ favoriteId: Int) async -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            let _: RemoveFavoriteResponse = try await apiClient.request(
                .removeFavorite(memberId: userId, favoriteId: favoriteId), body: nil
            )
            favorites.removeAll { $0.id == favoriteId }
            return true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
            return false
        } catch {
            self.error = "Fehler beim Entfernen"
            return false
        }
    }

    func refresh() async {
        await loadFavorites()
    }
}
