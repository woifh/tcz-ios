import XCTest
@testable import TCZApp

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = DashboardViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(sut.availability)
        XCTAssertNil(sut.bookingStatus)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.currentPage, 0)
    }

    func testTimeSlots_Has14Slots() {
        XCTAssertEqual(sut.timeSlots.count, 14)
        XCTAssertEqual(sut.timeSlots.first, "08:00")
        XCTAssertEqual(sut.timeSlots.last, "21:00")
    }

    func testCourtNumbers_Has6Courts() {
        XCTAssertEqual(sut.courtNumbers.count, 6)
        XCTAssertEqual(sut.courtNumbers, [1, 2, 3, 4, 5, 6])
    }

    // MARK: - Pagination Tests

    func testTotalPages_Is2() {
        XCTAssertEqual(sut.totalPages, 2)
    }

    func testCourtsPerPage_Is3() {
        XCTAssertEqual(sut.courtsPerPage, 3)
    }

    func testCourtIndicesForPage_Page0() {
        let range = sut.courtIndicesForPage(0)
        XCTAssertEqual(range, 0..<3)
    }

    func testCourtIndicesForPage_Page1() {
        let range = sut.courtIndicesForPage(1)
        XCTAssertEqual(range, 3..<6)
    }

    func testPageLabelForPage_Page0() {
        XCTAssertEqual(sut.pageLabelForPage(0), "Plätze 1-3")
    }

    func testPageLabelForPage_Page1() {
        XCTAssertEqual(sut.pageLabelForPage(1), "Plätze 4-6")
    }

    // MARK: - Load Availability Tests

    func testLoadAvailability_Success() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response

        await sut.loadAvailability()

        XCTAssertNotNil(sut.availability)
        XCTAssertEqual(sut.availability?.date, "2024-01-20")
        XCTAssertEqual(sut.availability?.courts.count, 2)
    }

    func testLoadAvailability_Failure_SetsError() async {
        mockAPIClient.mockError = APIError.serverError(500, nil)

        await sut.loadAvailability()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Load Booking Status Tests

    func testLoadBookingStatus_WithoutUserId_ReturnsNil() async {
        await sut.loadBookingStatus()

        XCTAssertNil(sut.bookingStatus)
        XCTAssertFalse(mockAPIClient.requestCalled)
    }

    func testLoadBookingStatus_WithUserId_Success() async throws {
        sut.setCurrentUserId("test-user-id")
        let response: BookingStatusResponse = try TestData.decodeJSON(TestData.testBookingStatusResponse)
        mockAPIClient.mockResponse = response

        await sut.loadBookingStatus()

        XCTAssertNotNil(sut.bookingStatus)
        XCTAssertTrue(sut.bookingStatus?.limits.regularReservations.canBook ?? false)
    }

    // MARK: - Get Slot Tests

    func testGetSlot_WhenNoAvailability_ReturnsNil() {
        let slot = sut.getSlot(courtIndex: 0, time: "10:00")
        XCTAssertNil(slot)
    }

    func testGetSlot_OccupiedSlot_ReturnsReservedStatus() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        let slot = sut.getSlot(courtIndex: 0, time: "10:00")

        XCTAssertNotNil(slot)
        XCTAssertEqual(slot?.status, .reserved)
    }

    func testGetSlot_AvailableSlot_ReturnsAvailableStatus() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        let slot = sut.getSlot(courtIndex: 0, time: "11:00")

        XCTAssertNotNil(slot)
        XCTAssertEqual(slot?.status, .available)
    }

    // MARK: - Court Info Tests

    func testGetCourtInfo_WhenNoAvailability_ReturnsFallback() {
        let info = sut.getCourtInfo(courtIndex: 0)

        XCTAssertEqual(info.id, 1)
        XCTAssertEqual(info.number, 1)
    }

    func testGetCourtInfo_WithAvailability_ReturnsActualInfo() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        let info = sut.getCourtInfo(courtIndex: 0)

        XCTAssertEqual(info.id, 1)
        XCTAssertEqual(info.number, 1)
    }

    // MARK: - Date Navigation Tests

    func testChangeDate_Positive() {
        let initialDate = sut.selectedDate
        sut.changeDate(by: 1)

        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: initialDate)
        XCTAssertEqual(Calendar.current.startOfDay(for: sut.selectedDate),
                       Calendar.current.startOfDay(for: expectedDate!))
    }

    func testChangeDate_Negative() {
        let initialDate = sut.selectedDate
        sut.changeDate(by: -1)

        let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: initialDate)
        XCTAssertEqual(Calendar.current.startOfDay(for: sut.selectedDate),
                       Calendar.current.startOfDay(for: expectedDate!))
    }

    func testGoToToday_SetsSelectedDateToToday() {
        // First change date to tomorrow
        sut.changeDate(by: 5)

        sut.goToToday()

        XCTAssertTrue(Calendar.current.isDateInToday(sut.selectedDate))
    }

    // MARK: - Booking Permission Tests

    func testCanBookSlot_WhenAvailable_ReturnsTrue() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        // Get an available slot in the future
        sut.changeDate(by: 1) // Move to tomorrow to ensure slots aren't in past
        let slot: TimeSlot = try! TestData.decodeJSON("""
        {"time": "15:00", "status": "available"}
        """)

        XCTAssertTrue(sut.canBookSlot(slot, time: "15:00"))
    }

    func testCanBookSlot_WhenReserved_ReturnsFalse() throws {
        let slot: TimeSlot = try TestData.decodeJSON("""
        {"time": "10:00", "status": "reserved"}
        """)
        XCTAssertFalse(sut.canBookSlot(slot, time: "10:00"))
    }

    func testCanBookSlot_WhenNil_ReturnsFalse() {
        XCTAssertFalse(sut.canBookSlot(nil, time: "10:00"))
    }

    // MARK: - User Booking Tests

    func testIsUserBooking_WithMatchingUserId_ReturnsTrue() throws {
        sut.setCurrentUserId("test-user-id")
        let slot: TimeSlot = try TestData.decodeJSON("""
        {
            "time": "10:00",
            "status": "reserved",
            "details": {
                "booked_for": "Test User",
                "booked_for_id": "test-user-id",
                "reservation_id": 123,
                "can_cancel": true
            }
        }
        """)

        XCTAssertTrue(sut.isUserBooking(slot))
    }

    func testIsUserBooking_WithDifferentUserId_ReturnsFalse() throws {
        sut.setCurrentUserId("different-user-id")
        let slot: TimeSlot = try TestData.decodeJSON("""
        {
            "time": "10:00",
            "status": "reserved",
            "details": {
                "booked_for": "Test User",
                "booked_for_id": "test-user-id",
                "reservation_id": 123,
                "can_cancel": true
            }
        }
        """)

        XCTAssertFalse(sut.isUserBooking(slot))
    }

    // MARK: - Formatted Date Tests

    func testIsToday_WhenToday_ReturnsTrue() {
        XCTAssertTrue(sut.isToday)
    }

    func testIsToday_WhenNotToday_ReturnsFalse() {
        sut.changeDate(by: 1)
        XCTAssertFalse(sut.isToday)
    }

    // MARK: - Cache Tests

    func testClearCache_ClearsAvailabilityCache() async throws {
        let response: AvailabilityResponse = try TestData.decodeJSON(TestData.testAvailabilityResponse)
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        sut.clearCache()
        mockAPIClient.reset()

        // Loading again should call API
        mockAPIClient.mockResponse = response
        await sut.loadAvailability()

        XCTAssertTrue(mockAPIClient.requestCalled)
    }
}
