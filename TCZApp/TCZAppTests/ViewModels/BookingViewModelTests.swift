import XCTest
@testable import TCZApp

@MainActor
final class BookingViewModelTests: XCTestCase {
    var sut: BookingViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = BookingViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(sut.selectedMemberId)
        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isLoadingFavorites)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isSuccess)
        XCTAssertEqual(sut.searchQuery, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
        XCTAssertFalse(sut.showSearch)
    }

    // MARK: - Setup Tests

    func testSetup_SetsPropertiesCorrectly() {
        mockAPIClient.mockResponse = TestData.testFavoritesResponse

        sut.setup(
            courtId: 1,
            courtNumber: 1,
            time: "10:00",
            date: Date(),
            currentUserId: "test-user-id"
        )

        XCTAssertEqual(sut.courtId, 1)
        XCTAssertEqual(sut.courtNumber, 1)
        XCTAssertEqual(sut.time, "10:00")
        XCTAssertEqual(sut.currentUserId, "test-user-id")
        XCTAssertEqual(sut.selectedMemberId, "test-user-id")
    }

    // MARK: - Load Favorites Tests

    func testLoadFavorites_Success() async {
        sut.currentUserId = "test-user-id"
        mockAPIClient.mockResponse = TestData.testFavoritesResponse

        await sut.loadFavorites()

        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.name, "Partner Name")
        XCTAssertFalse(sut.isLoadingFavorites)
    }

    func testLoadFavorites_WithoutUserId_DoesNothing() async {
        await sut.loadFavorites()

        XCTAssertFalse(mockAPIClient.requestCalled)
        XCTAssertTrue(sut.favorites.isEmpty)
    }

    func testLoadFavorites_Failure_DoesNotCrash() async {
        sut.currentUserId = "test-user-id"
        mockAPIClient.mockError = APIError.serverError(500)

        await sut.loadFavorites()

        XCTAssertTrue(sut.favorites.isEmpty)
        XCTAssertFalse(sut.isLoadingFavorites)
    }

    // MARK: - Create Booking Tests

    func testCreateBooking_WithoutSelectedMember_ReturnsFailure() async {
        sut.selectedMemberId = nil

        let result = await sut.createBooking()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Bitte wähle ein Mitglied aus")
    }

    func testCreateBooking_Success() async {
        sut.selectedMemberId = "test-user-id"
        sut.courtId = 1
        sut.date = Date()
        sut.time = "10:00"

        let response: BookingCreatedResponse = try! TestData.decodeJSON("""
        {
            "message": "Buchung erfolgreich"
        }
        """)
        mockAPIClient.mockResponse = response

        let result = await sut.createBooking()

        XCTAssertTrue(result)
        XCTAssertTrue(sut.isSuccess)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testCreateBooking_APIError_SetsErrorMessage() async {
        sut.selectedMemberId = "test-user-id"
        mockAPIClient.mockError = APIError.forbidden("Keine Berechtigung")

        let result = await sut.createBooking()

        XCTAssertFalse(result)
        XCTAssertFalse(sut.isSuccess)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testCreateBooking_GenericError_SetsGenericErrorMessage() async {
        sut.selectedMemberId = "test-user-id"
        mockAPIClient.mockError = NSError(domain: "Test", code: 1)

        let result = await sut.createBooking()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Fehler beim Erstellen der Buchung")
    }

    // MARK: - Time Range Tests

    func testTimeRange_FormatsCorrectly() {
        sut.time = "10:00"
        XCTAssertEqual(sut.timeRange, "10:00 - 11:00")
    }

    func testTimeRange_HandlesAfternoon() {
        sut.time = "14:00"
        XCTAssertEqual(sut.timeRange, "14:00 - 15:00")
    }

    // MARK: - Search Tests

    func testSearchMembers_WithEmptyQuery_ClearsResults() async {
        sut.searchResults = [TestData.testMemberSummary]

        await sut.searchMembers(query: "")

        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchMembers_WithWhitespaceQuery_ClearsResults() async {
        sut.searchResults = [TestData.testMemberSummary]

        await sut.searchMembers(query: "   ")

        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchMembers_Success_FiltersOutSelfAndFavorites() async {
        sut.currentUserId = "test-user-id"
        sut.favorites = [TestData.testMemberSummary]

        let response: SearchResponse = try! TestData.decodeJSON("""
        {
            "results": [
                {"id": "new-user-id", "name": "New User", "email": "new@example.com"},
                {"id": "test-user-id", "name": "Self", "email": "self@example.com"},
                {"id": "partner-id", "name": "Partner Name", "email": "partner@example.com"}
            ]
        }
        """)
        mockAPIClient.mockResponse = response

        await sut.searchMembers(query: "test")

        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.id, "new-user-id")
    }

    func testSearchMembers_Failure_ClearsResults() async {
        mockAPIClient.mockError = APIError.serverError(500)

        await sut.searchMembers(query: "test")

        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Reset Search Tests

    func testResetSearch_ClearsSearchState() {
        sut.showSearch = true
        sut.searchQuery = "test"
        sut.searchResults = [TestData.testMemberSummary]

        sut.resetSearch()

        XCTAssertFalse(sut.showSearch)
        XCTAssertEqual(sut.searchQuery, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    // MARK: - Toggle Search Tests

    func testToggleSearch_TogglesShowSearch() {
        XCTAssertFalse(sut.showSearch)

        sut.toggleSearch()
        XCTAssertTrue(sut.showSearch)

        sut.toggleSearch()
        XCTAssertFalse(sut.showSearch)
    }

    func testToggleSearch_WhenClosing_ResetsSearch() {
        sut.showSearch = true
        sut.searchQuery = "test"
        sut.searchResults = [TestData.testMemberSummary]

        sut.toggleSearch()

        XCTAssertFalse(sut.showSearch)
        XCTAssertEqual(sut.searchQuery, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
    }
}
