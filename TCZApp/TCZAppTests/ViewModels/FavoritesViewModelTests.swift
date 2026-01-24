import XCTest
@testable import TCZApp

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    var sut: FavoritesViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = FavoritesViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isSearching)
        XCTAssertFalse(sut.isAdding)
        XCTAssertNil(sut.removingId)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.searchQuery, "")
        XCTAssertNil(sut.currentUserId)
    }

    func testSetCurrentUserId() {
        sut.setCurrentUserId("user-123")
        XCTAssertEqual(sut.currentUserId, "user-123")
    }

    // MARK: - Load Favorites Tests

    func testLoadFavorites_WithoutUserId_DoesNothing() async {
        mockAPIClient.mockResponse = TestData.testFavoritesResponse

        await sut.loadFavorites()

        XCTAssertFalse(mockAPIClient.requestCalled)
        XCTAssertTrue(sut.favorites.isEmpty)
    }

    func testLoadFavorites_Success() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockResponse = TestData.testFavoritesResponse

        await sut.loadFavorites()

        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.id, "partner-id")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testLoadFavorites_APIError_SetsError() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockError = APIError.unauthorized

        await sut.loadFavorites()

        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadFavorites_GenericError_SetsGenericError() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        await sut.loadFavorites()

        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertEqual(sut.error, "Fehler beim Laden der Favoriten")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Search Members Tests

    func testSearchMembers_WithEmptyQuery_ClearsResults() async {
        sut.searchResults = [TestData.testMemberSummary]

        await sut.searchMembers(query: "")

        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(mockAPIClient.requestCalled)
    }

    func testSearchMembers_WithWhitespaceQuery_ClearsResults() async {
        sut.searchResults = [TestData.testMemberSummary]

        await sut.searchMembers(query: "   ")

        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(mockAPIClient.requestCalled)
    }

    func testSearchMembers_Success_ReturnsResults() async {
        let searchResponse = SearchResponse(results: [TestData.testMemberSummary])
        mockAPIClient.mockResponse = searchResponse

        await sut.searchMembers(query: "Partner")

        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertFalse(sut.isSearching)
    }

    func testSearchMembers_FiltersOutCurrentUser() async {
        sut.setCurrentUserId("partner-id")
        let searchResponse = SearchResponse(results: [TestData.testMemberSummary])
        mockAPIClient.mockResponse = searchResponse

        await sut.searchMembers(query: "Partner")

        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchMembers_FiltersOutAlreadyFavorited() async {
        sut.setCurrentUserId("other-user")
        mockAPIClient.mockResponse = TestData.testFavoritesResponse
        await sut.loadFavorites()

        mockAPIClient.reset()
        let searchResponse = SearchResponse(results: [TestData.testMemberSummary])
        mockAPIClient.mockResponse = searchResponse

        await sut.searchMembers(query: "Partner")

        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchMembers_Failure_ClearsResults() async {
        sut.searchResults = [TestData.testMemberSummary]
        mockAPIClient.mockError = APIError.serverError(500, nil)

        await sut.searchMembers(query: "Test")

        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Add Favorite Tests

    func testAddFavorite_WithoutUserId_ReturnsFalse() async {
        let result = await sut.addFavorite("member-123")

        XCTAssertFalse(result)
        XCTAssertFalse(mockAPIClient.requestCalled)
    }

    func testAddFavorite_Success_AddsFavorite() async {
        sut.setCurrentUserId("user-123")
        let addResponse = AddFavoriteResponse(message: "Added", favourite: TestData.testMemberSummary)
        mockAPIClient.mockResponse = addResponse

        let result = await sut.addFavorite("partner-id")

        XCTAssertTrue(result)
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.id, "partner-id")
        XCTAssertFalse(sut.isAdding)
        XCTAssertEqual(sut.searchQuery, "")
    }

    func testAddFavorite_Success_RemovesFromSearchResults() async {
        sut.setCurrentUserId("user-123")
        sut.searchResults = [TestData.testMemberSummary]
        let addResponse = AddFavoriteResponse(message: "Added", favourite: TestData.testMemberSummary)
        mockAPIClient.mockResponse = addResponse

        let result = await sut.addFavorite("partner-id")

        XCTAssertTrue(result)
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testAddFavorite_APIError_ReturnsFalseWithError() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockError = APIError.badRequest("Already favorited")

        let result = await sut.addFavorite("partner-id")

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isAdding)
    }

    func testAddFavorite_GenericError_ReturnsFalseWithGenericError() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        let result = await sut.addFavorite("partner-id")

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Fehler beim Hinzufuegen")
        XCTAssertFalse(sut.isAdding)
    }

    // MARK: - Remove Favorite Tests

    func testRemoveFavorite_WithoutUserId_ReturnsFalse() async {
        let result = await sut.removeFavorite("partner-id")

        XCTAssertFalse(result)
        XCTAssertFalse(mockAPIClient.requestCalled)
    }

    func testRemoveFavorite_Success_RemovesFavorite() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockResponse = TestData.testFavoritesResponse
        await sut.loadFavorites()
        XCTAssertEqual(sut.favorites.count, 1)

        mockAPIClient.reset()
        let removeResponse = RemoveFavoriteResponse(message: "Removed")
        mockAPIClient.mockResponse = removeResponse

        let result = await sut.removeFavorite("partner-id")

        XCTAssertTrue(result)
        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertNil(sut.removingId)
    }

    func testRemoveFavorite_APIError_ReturnsFalseWithError() async {
        sut.setCurrentUserId("user-123")
        sut.favorites = [TestData.testMemberSummary]
        mockAPIClient.mockError = APIError.notFound(nil)

        let result = await sut.removeFavorite("partner-id")

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertNil(sut.removingId)
        XCTAssertEqual(sut.favorites.count, 1)
    }

    func testRemoveFavorite_GenericError_ReturnsFalseWithGenericError() async {
        sut.setCurrentUserId("user-123")
        sut.favorites = [TestData.testMemberSummary]
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        let result = await sut.removeFavorite("partner-id")

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Fehler beim Entfernen")
        XCTAssertNil(sut.removingId)
    }

    // MARK: - Refresh Tests

    func testRefresh_CallsLoadFavorites() async {
        sut.setCurrentUserId("user-123")
        mockAPIClient.mockResponse = TestData.testFavoritesResponse

        await sut.refresh()

        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.favorites.count, 1)
    }
}
