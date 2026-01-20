import Foundation
@testable import TCZApp

enum TestData {
    // MARK: - JSON Test Data

    static let testMemberJSON = """
    {
        "id": "test-user-id",
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
        "has_profile_picture": true,
        "profile_picture_version": 1,
        "fee_paid": true,
        "payment_confirmation_requested": false,
        "role": "member",
        "membership_type": "regular",
        "is_active": true
    }
    """

    static let testLoginResponseJSON = """
    {
        "user": {
            "id": "test-user-id",
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
            "has_profile_picture": true,
            "profile_picture_version": 1,
            "fee_paid": true,
            "payment_confirmation_requested": false,
            "role": "member",
            "membership_type": "regular",
            "is_active": true
        },
        "access_token": "test-access-token-12345"
    }
    """

    static let testMemberSummaryJSON = """
    {
        "id": "partner-id",
        "name": "Partner Name",
        "email": "partner@example.com",
        "has_profile_picture": false,
        "profile_picture_version": null
    }
    """

    static let testFavoritesResponseJSON = """
    {
        "favourites": [
            {
                "id": "partner-id",
                "name": "Partner Name",
                "email": "partner@example.com",
                "has_profile_picture": false,
                "profile_picture_version": null
            }
        ]
    }
    """

    static let testReservation = """
    {
        "id": 123,
        "court_id": 1,
        "court_number": 1,
        "date": "2024-01-20",
        "start_time": "10:00",
        "end_time": "11:00",
        "booked_for": "Max Mustermann",
        "booked_for_id": "test-user-id",
        "booked_by": "Max Mustermann",
        "booked_by_id": "test-user-id",
        "status": "active",
        "is_short_notice": false,
        "is_active": true,
        "can_cancel": true
    }
    """

    static let testReservationsResponse = """
    {
        "current_time": "2024-01-20T10:00:00",
        "reservations": [
            {
                "id": 123,
                "court_id": 1,
                "court_number": 1,
                "date": "2024-01-20",
                "start_time": "10:00",
                "end_time": "11:00",
                "booked_for": "Max Mustermann",
                "booked_for_id": "test-user-id",
                "booked_by": "Max Mustermann",
                "booked_by_id": "test-user-id",
                "status": "active",
                "is_short_notice": false,
                "is_active": true,
                "can_cancel": true
            }
        ],
        "statistics": {
            "total_count": 1,
            "active_count": 1
        }
    }
    """

    static let testAvailabilityResponse = """
    {
        "date": "2024-01-20",
        "current_hour": 10,
        "courts": [
            {
                "court_id": 1,
                "court_number": 1,
                "occupied": [
                    {
                        "time": "10:00",
                        "status": "reserved",
                        "details": {
                            "booked_for": "Max Mustermann",
                            "booked_for_id": "test-user-id",
                            "reservation_id": 123,
                            "can_cancel": true
                        }
                    }
                ]
            },
            {
                "court_id": 2,
                "court_number": 2,
                "occupied": []
            }
        ]
    }
    """

    static let testBookingStatusResponse = """
    {
        "current_time": "2024-01-20T10:00:00",
        "user_id": "test-user-id",
        "limits": {
            "regular_reservations": {
                "limit": 2,
                "current": 1,
                "available": 1,
                "can_book": true
            },
            "short_notice_bookings": {
                "limit": 1,
                "current": 0,
                "available": 1,
                "can_book": true
            }
        },
        "active_reservations": {
            "total": 1,
            "regular": 1,
            "short_notice": 0
        }
    }
    """

    // MARK: - Decoded Test Objects

    static var testMember: Member {
        try! decodeJSON(testMemberJSON)
    }

    static var testLoginResponse: LoginResponse {
        try! decodeJSON(testLoginResponseJSON)
    }

    static var testMemberSummary: MemberSummary {
        try! decodeJSON(testMemberSummaryJSON)
    }

    static var testFavoritesResponse: FavoritesResponse {
        try! decodeJSON(testFavoritesResponseJSON)
    }

    // MARK: - Helper Functions

    static func decodeJSON<T: Decodable>(_ json: String) throws -> T {
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    static func createMember(
        feePaid: Bool? = nil,
        paymentConfirmationRequested: Bool? = nil,
        emailVerified: Bool? = nil
    ) -> Member {
        let json = """
        {
            "id": "test",
            "firstname": "Test",
            "lastname": "User",
            "email": "test@example.com",
            "name": "Test User"
            \(feePaid.map { ", \"fee_paid\": \($0)" } ?? "")
            \(paymentConfirmationRequested.map { ", \"payment_confirmation_requested\": \($0)" } ?? "")
            \(emailVerified.map { ", \"email_verified\": \($0)" } ?? "")
        }
        """
        return try! decodeJSON(json)
    }
}
