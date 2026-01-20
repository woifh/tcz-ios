import XCTest
@testable import TCZApp

final class ModelDecodingTests: XCTestCase {

    // MARK: - Member Tests

    func testMember_DecodesFromJSON() throws {
        let json = """
        {
            "id": "user-123",
            "firstname": "Max",
            "lastname": "Mustermann",
            "email": "max@example.com",
            "name": "Max Mustermann",
            "street": "Teststraße 1",
            "city": "Teststadt",
            "zip_code": "12345",
            "phone": "0123456789",
            "notifications_enabled": true,
            "notify_own_bookings": true,
            "notify_other_bookings": false,
            "notify_court_blocked": true,
            "notify_booking_overridden": true,
            "email_verified": true,
            "fee_paid": true,
            "payment_confirmation_requested": false,
            "role": "member",
            "membership_type": "regular",
            "is_active": true
        }
        """

        let member: Member = try decodeJSON(json)

        XCTAssertEqual(member.id, "user-123")
        XCTAssertEqual(member.firstname, "Max")
        XCTAssertEqual(member.lastname, "Mustermann")
        XCTAssertEqual(member.email, "max@example.com")
        XCTAssertEqual(member.name, "Max Mustermann")
        XCTAssertEqual(member.street, "Teststraße 1")
        XCTAssertEqual(member.city, "Teststadt")
        XCTAssertEqual(member.zipCode, "12345")
        XCTAssertEqual(member.phone, "0123456789")
        XCTAssertEqual(member.notificationsEnabled, true)
        XCTAssertEqual(member.emailVerified, true)
        XCTAssertEqual(member.feePaid, true)
    }

    func testMember_DecodesWithOptionalFieldsNil() throws {
        let json = """
        {
            "id": "user-123",
            "firstname": "Max",
            "lastname": "Mustermann",
            "email": "max@example.com",
            "name": "Max Mustermann"
        }
        """

        let member: Member = try decodeJSON(json)

        XCTAssertNil(member.street)
        XCTAssertNil(member.phone)
        XCTAssertNil(member.feePaid)
    }

    func testMember_PaymentReminder_WhenFeePaidFalse() throws {
        let member = createMember(feePaid: false, paymentConfirmationRequested: false)
        XCTAssertTrue(member.shouldShowPaymentReminder)
    }

    func testMember_PaymentReminder_WhenFeePaidTrue() throws {
        let member = createMember(feePaid: true, paymentConfirmationRequested: false)
        XCTAssertFalse(member.shouldShowPaymentReminder)
    }

    func testMember_PaymentReminder_WhenConfirmationRequested() throws {
        let member = createMember(feePaid: false, paymentConfirmationRequested: true)
        XCTAssertFalse(member.shouldShowPaymentReminder)
    }

    func testMember_PendingPaymentConfirmation() throws {
        let member = createMember(feePaid: false, paymentConfirmationRequested: true)
        XCTAssertTrue(member.hasPendingPaymentConfirmation)
    }

    func testMember_EmailVerificationReminder() throws {
        let member = createMember(emailVerified: false)
        XCTAssertTrue(member.shouldShowEmailVerificationReminder)
    }

    // MARK: - Reservation Tests

    func testReservation_DecodesFromJSON() throws {
        let reservation: Reservation = try decodeJSON(TestData.testReservation)

        XCTAssertEqual(reservation.id, 123)
        XCTAssertEqual(reservation.courtId, 1)
        XCTAssertEqual(reservation.courtNumber, 1)
        XCTAssertEqual(reservation.date, "2024-01-20")
        XCTAssertEqual(reservation.startTime, "10:00")
        XCTAssertEqual(reservation.endTime, "11:00")
        XCTAssertEqual(reservation.bookedFor, "Max Mustermann")
        XCTAssertEqual(reservation.bookedForId, "test-user-id")
        XCTAssertEqual(reservation.status, "active")
        XCTAssertFalse(reservation.isShortNotice)
        XCTAssertTrue(reservation.canCancel)
    }

    func testReservation_TimeRange() throws {
        let reservation: Reservation = try decodeJSON(TestData.testReservation)
        XCTAssertEqual(reservation.timeRange, "10:00 - 11:00")
    }

    func testReservation_FormattedDate() throws {
        let reservation: Reservation = try decodeJSON(TestData.testReservation)
        XCTAssertEqual(reservation.formattedDate, "20.01.2024")
    }

    func testReservation_IsSuspended() throws {
        let json = """
        {
            "id": 123,
            "court_id": 1,
            "date": "2024-01-20",
            "start_time": "10:00",
            "end_time": "11:00",
            "booked_for_id": "test-user-id",
            "booked_by_id": "test-user-id",
            "status": "suspended",
            "is_short_notice": false
        }
        """
        let reservation: Reservation = try decodeJSON(json)
        XCTAssertTrue(reservation.isSuspended)
    }

    // MARK: - AvailabilityResponse Tests

    func testAvailabilityResponse_DecodesFromJSON() throws {
        let response: AvailabilityResponse = try decodeJSON(TestData.testAvailabilityResponse)

        XCTAssertEqual(response.date, "2024-01-20")
        XCTAssertEqual(response.currentHour, 10)
        XCTAssertEqual(response.courts.count, 2)
    }

    func testCourtAvailability_DecodesOccupiedSlots() throws {
        let response: AvailabilityResponse = try decodeJSON(TestData.testAvailabilityResponse)
        let court = response.courts[0]

        XCTAssertEqual(court.courtId, 1)
        XCTAssertEqual(court.courtNumber, 1)
        XCTAssertEqual(court.occupied.count, 1)
        XCTAssertEqual(court.occupied[0].time, "10:00")
        XCTAssertEqual(court.occupied[0].status, .reserved)
    }

    func testSlotStatus_AllCases() throws {
        XCTAssertEqual(SlotStatus(rawValue: "available"), .available)
        XCTAssertEqual(SlotStatus(rawValue: "reserved"), .reserved)
        XCTAssertEqual(SlotStatus(rawValue: "short_notice"), .shortNotice)
        XCTAssertEqual(SlotStatus(rawValue: "blocked"), .blocked)
        XCTAssertEqual(SlotStatus(rawValue: "blocked_temporary"), .blockedTemporary)
    }

    // MARK: - BookingStatusResponse Tests

    func testBookingStatusResponse_DecodesFromJSON() throws {
        let response: BookingStatusResponse = try decodeJSON(TestData.testBookingStatusResponse)

        XCTAssertEqual(response.userId, "test-user-id")
        XCTAssertNotNil(response.limits)
        XCTAssertEqual(response.limits.regularReservations.current, 1)
        XCTAssertEqual(response.limits.regularReservations.limit, 2)
        XCTAssertTrue(response.limits.regularReservations.canBook)
        XCTAssertEqual(response.activeReservations.total, 1)
    }

    // MARK: - LoginResponse Tests

    func testLoginResponse_DecodesFromJSON() throws {
        let json = """
        {
            "user": {
                "id": "user-123",
                "firstname": "Max",
                "lastname": "Mustermann",
                "email": "max@example.com",
                "name": "Max Mustermann"
            },
            "access_token": "jwt-token-12345"
        }
        """

        let response: LoginResponse = try decodeJSON(json)

        XCTAssertEqual(response.user.id, "user-123")
        XCTAssertEqual(response.accessToken, "jwt-token-12345")
    }

    // MARK: - ErrorResponse Tests

    func testErrorResponse_DecodesSimpleError() throws {
        let json = """
        {
            "error": "Ungültige Anfrage"
        }
        """

        let response: ErrorResponse = try decodeJSON(json)

        XCTAssertEqual(response.error, "Ungültige Anfrage")
        XCTAssertEqual(response.fullErrorMessage, "Ungültige Anfrage")
    }

    func testErrorResponse_DecodesWithActiveSessions() throws {
        let json = """
        {
            "error": "Buchungslimit erreicht",
            "active_sessions": [
                {
                    "date": "2024-01-20",
                    "start_time": "10:00",
                    "court_number": 1
                }
            ]
        }
        """

        let response: ErrorResponse = try decodeJSON(json)

        XCTAssertEqual(response.error, "Buchungslimit erreicht")
        XCTAssertNotNil(response.activeSessions)
        XCTAssertEqual(response.activeSessions?.count, 1)
        XCTAssertTrue(response.fullErrorMessage.contains("20.01."))
    }

    // MARK: - Helper Methods

    private func decodeJSON<T: Decodable>(_ json: String) throws -> T {
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func createMember(
        feePaid: Bool? = nil,
        paymentConfirmationRequested: Bool? = nil,
        emailVerified: Bool? = nil
    ) -> Member {
        var optionalFields = ""
        if let feePaid = feePaid {
            optionalFields += ", \"fee_paid\": \(feePaid)"
        }
        if let paymentConfirmationRequested = paymentConfirmationRequested {
            optionalFields += ", \"payment_confirmation_requested\": \(paymentConfirmationRequested)"
        }
        if let emailVerified = emailVerified {
            optionalFields += ", \"email_verified\": \(emailVerified)"
        }

        let json = """
        {
            "id": "test",
            "firstname": "Test",
            "lastname": "User",
            "email": "test@example.com",
            "name": "Test User"\(optionalFields)
        }
        """
        return try! decodeJSON(json)
    }
}
