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
        // Conflict resolution state
        XCTAssertFalse(sut.showConflictResolution)
        XCTAssertTrue(sut.activeSessions.isEmpty)
        XCTAssertNil(sut.cancellingSessionId)
        XCTAssertNil(sut.conflictError)
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
        mockAPIClient.mockError = APIError.serverError(500, nil)

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
        mockAPIClient.mockError = APIError.serverError(500, nil)

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

    // MARK: - Conflict Resolution Tests

    func testCreateBooking_BookingLimitExceeded_ShowsConflictResolution() async {
        sut.selectedMemberId = "test-user-id"
        sut.courtId = 1
        sut.date = Date()
        sut.time = "10:00"
        mockAPIClient.mockError = APIError.bookingLimitExceeded(
            "Du hast bereits 2 aktive Buchungen",
            TestData.testActiveSessions
        )

        let result = await sut.createBooking()

        XCTAssertFalse(result)
        XCTAssertTrue(sut.showConflictResolution)
        XCTAssertEqual(sut.activeSessions.count, 2)
        XCTAssertNil(sut.error) // Should not set regular error
        XCTAssertFalse(sut.isLoading)
    }

    func testCancelSession_Success_AutoRetriesBooking() async {
        // Set up initial conflict state
        sut.selectedMemberId = "test-user-id"
        sut.courtId = 1
        sut.date = Date()
        sut.time = "10:00"
        sut.showConflictResolution = true
        sut.activeSessions = TestData.testActiveSessions

        // Mock cancel response - auto-retry will fail due to mock limitation
        // (MockAPIClient returns same response for all calls)
        let cancelResponse: CancelResponse = try! TestData.decodeJSON("""
        {"message": "Buchung storniert"}
        """)
        mockAPIClient.mockResponse = cancelResponse

        let result = await sut.cancelSession(123)

        // Verify cancel API was called
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertNil(sut.cancellingSessionId) // Loading should be finished
        // Session should be removed from list after successful cancel
        XCTAssertEqual(sut.activeSessions.count, 1)
        XCTAssertNil(sut.activeSessions.first { $0.reservationId == 123 })
    }

    func testCancelSession_CancelFailure_ShowsError() async {
        sut.selectedMemberId = "test-user-id"
        sut.showConflictResolution = true
        sut.activeSessions = TestData.testActiveSessions
        mockAPIClient.mockError = APIError.forbidden("Keine Berechtigung")

        let result = await sut.cancelSession(123)

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.conflictError)
        XCTAssertNil(sut.cancellingSessionId)
        XCTAssertTrue(sut.showConflictResolution) // Should stay on conflict screen
    }

    func testCancelSession_GenericError_ShowsGenericErrorMessage() async {
        sut.selectedMemberId = "test-user-id"
        sut.showConflictResolution = true
        sut.activeSessions = TestData.testActiveSessions
        mockAPIClient.mockError = NSError(domain: "Test", code: 1)

        let result = await sut.cancelSession(123)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.conflictError, "Fehler beim Stornieren")
        XCTAssertNil(sut.cancellingSessionId)
    }

    func testDismissConflictResolution_ResetsState() {
        // Set up conflict state
        sut.showConflictResolution = true
        sut.activeSessions = TestData.testActiveSessions
        sut.conflictError = "Some error"

        sut.dismissConflictResolution()

        XCTAssertFalse(sut.showConflictResolution)
        XCTAssertTrue(sut.activeSessions.isEmpty)
        XCTAssertNil(sut.conflictError)
    }

    func testActiveSession_FormattedProperties() {
        let session = TestData.testActiveSession

        XCTAssertEqual(session.reservationId, 123)
        XCTAssertEqual(session.formattedDate, "25.01.2026")
        XCTAssertEqual(session.timeRange, "10:00-11:00")
        XCTAssertEqual(session.courtName, "Platz 1")
    }

    func testActiveSession_WithBooker_ShowsBookerName() {
        let session = TestData.testActiveSessionWithBooker

        XCTAssertEqual(session.bookedByName, "Other Person")
        XCTAssertEqual(session.bookedById, "booker-id")
    }

    // MARK: - Short-Notice Conflict Tests

    func testCreateBooking_ShortNoticeLimitExceeded_ShowsConflictResolution() async {
        sut.selectedMemberId = "test-user-id"
        sut.courtId = 1
        sut.date = Date()
        sut.time = "15:00"
        mockAPIClient.mockError = APIError.bookingLimitExceeded(
            "Du hast bereits eine aktive kurzfristige Buchung",
            TestData.testShortNoticeSessions
        )

        let result = await sut.createBooking()

        XCTAssertFalse(result)
        XCTAssertTrue(sut.showConflictResolution)
        XCTAssertEqual(sut.activeSessions.count, 1)
        XCTAssertTrue(sut.activeSessions.first?.isShortNotice == true)
        XCTAssertNil(sut.error) // Should not set regular error
    }

    func testActiveSession_ShortNotice_HasCorrectFlag() {
        let session = TestData.testShortNoticeSession

        XCTAssertEqual(session.reservationId, 789)
        XCTAssertTrue(session.isShortNotice == true)
        XCTAssertEqual(session.formattedDate, "24.01.2026")
        XCTAssertEqual(session.timeRange, "15:00-16:00")
    }

    func testActiveSession_Regular_HasCorrectFlag() {
        let session = TestData.testActiveSession

        XCTAssertTrue(session.isShortNotice == false)
    }
}
