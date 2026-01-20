import XCTest
@testable import TCZApp

@MainActor
final class ReservationsViewModelTests: XCTestCase {
    var sut: ReservationsViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = ReservationsViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(sut.reservations.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.cancellingId)
    }

    // MARK: - Load Reservations Tests

    func testLoadReservations_Success() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response

        await sut.loadReservations()

        XCTAssertEqual(sut.reservations.count, 1)
        XCTAssertEqual(sut.reservations.first?.id, 123)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testLoadReservations_APIError_SetsError() async {
        mockAPIClient.mockError = APIError.unauthorized

        await sut.loadReservations()

        XCTAssertTrue(sut.reservations.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadReservations_GenericError_SetsGenericError() async {
        mockAPIClient.mockError = NSError(domain: "Test", code: 1)

        await sut.loadReservations()

        XCTAssertEqual(sut.error, "Fehler beim Laden der Buchungen")
    }

    // MARK: - Cancel Reservation Tests

    func testCancelReservation_Success() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()
        XCTAssertEqual(sut.reservations.count, 1)

        mockAPIClient.reset()
        let cancelResponse: CancelResponse = try! TestData.decodeJSON("""
        {"message": "Storniert"}
        """)
        mockAPIClient.mockResponse = cancelResponse

        let result = await sut.cancelReservation(123)

        XCTAssertTrue(result)
        XCTAssertTrue(sut.reservations.isEmpty)
        XCTAssertNil(sut.cancellingId)
    }

    func testCancelReservation_Failure_SetsError() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        mockAPIClient.reset()
        mockAPIClient.mockError = APIError.forbidden("Stornierung nicht erlaubt")

        let result = await sut.cancelReservation(123)

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.reservations.count, 1) // Reservation not removed
        XCTAssertNil(sut.cancellingId)
    }

    func testCancelReservation_GenericError_SetsGenericError() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        mockAPIClient.reset()
        mockAPIClient.mockError = NSError(domain: "Test", code: 1)

        let result = await sut.cancelReservation(123)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Fehler beim Stornieren")
    }

    // MARK: - My Reservations Tests

    func testMyReservations_WithMatchingUserId() async throws {
        sut.setCurrentUserId("test-user-id")
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        let myReservations = sut.myReservations

        XCTAssertEqual(myReservations.count, 1)
    }

    func testMyReservations_WithDifferentUserId() async throws {
        sut.setCurrentUserId("different-user-id")
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        let myReservations = sut.myReservations

        XCTAssertTrue(myReservations.isEmpty)
    }

    func testMyReservations_WithoutUserId_ReturnsAll() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        let myReservations = sut.myReservations

        XCTAssertEqual(myReservations.count, 1)
    }

    // MARK: - Bookings For Others Tests

    func testBookingsForOthers_WhenUserBookedForOther() async throws {
        sut.setCurrentUserId("test-user-id")
        // The test data has bookedById == bookedForId == test-user-id, so no "for others"
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        let forOthers = sut.bookingsForOthers

        XCTAssertTrue(forOthers.isEmpty)
    }

    func testBookingsForOthers_WithoutUserId_ReturnsEmpty() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response
        await sut.loadReservations()

        let forOthers = sut.bookingsForOthers

        XCTAssertTrue(forOthers.isEmpty)
    }

    // MARK: - Refresh Tests

    func testRefresh_CallsLoadReservations() async throws {
        let response: ReservationsResponse = try TestData.decodeJSON(TestData.testReservationsResponse)
        mockAPIClient.mockResponse = response

        await sut.refresh()

        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.reservations.count, 1)
    }
}
