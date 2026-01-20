import XCTest
@testable import TCZApp

@MainActor
final class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockAPIClient: MockAPIClient!
    var mockKeychainService: MockKeychainService!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        mockKeychainService = MockKeychainService()
        sut = AuthViewModel(apiClient: mockAPIClient, keychainService: mockKeychainService)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        mockKeychainService = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_NotAuthenticated() {
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Login Tests

    func testLogin_WithEmptyEmail_SetsErrorMessage() async {
        await sut.login(email: "", password: "password")

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Bitte E-Mail und Passwort eingeben")
    }

    func testLogin_WithEmptyPassword_SetsErrorMessage() async {
        await sut.login(email: "test@example.com", password: "")

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Bitte E-Mail und Passwort eingeben")
    }

    func testLogin_Success_SetsAuthenticatedState() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse

        await sut.login(email: "test@example.com", password: "password123")

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, "max@example.com")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_Success_StoresCredentialsInKeychain() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse

        await sut.login(email: "test@example.com", password: "password123")

        XCTAssertTrue(mockKeychainService.saveCalled)
        XCTAssertNotNil(mockKeychainService.storage["currentUser"])
        XCTAssertNotNil(mockKeychainService.storage["accessToken"])
    }

    func testLogin_Success_SetsAccessTokenOnAPIClient() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse

        await sut.login(email: "test@example.com", password: "password123")

        XCTAssertEqual(mockAPIClient.accessToken, "test-access-token-12345")
    }

    func testLogin_Failure_SetsErrorMessage() async {
        mockAPIClient.mockError = APIError.unauthorized

        await sut.login(email: "test@example.com", password: "wrongpassword")

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_NetworkError_SetsGenericErrorMessage() async {
        mockAPIClient.mockError = NSError(domain: "Network", code: -1)

        await sut.login(email: "test@example.com", password: "password123")

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.errorMessage, "Anmeldung fehlgeschlagen")
    }

    // MARK: - Logout Tests

    func testLogout_ClearsAuthenticatedState() async {
        // First login
        mockAPIClient.mockResponse = TestData.testLoginResponse
        await sut.login(email: "test@example.com", password: "password123")
        XCTAssertTrue(sut.isAuthenticated)

        // Then logout
        mockAPIClient.reset()
        await sut.logout()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    func testLogout_ClearsKeychain() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse
        await sut.login(email: "test@example.com", password: "password123")

        await sut.logout()

        XCTAssertTrue(mockKeychainService.deleteCalled)
        XCTAssertNil(mockKeychainService.storage["currentUser"])
        XCTAssertNil(mockKeychainService.storage["accessToken"])
    }

    func testLogout_ClearsAPIClientAuth() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse
        await sut.login(email: "test@example.com", password: "password123")

        await sut.logout()

        XCTAssertNil(mockAPIClient.accessToken)
    }

    // MARK: - Session Restoration Tests

    func testSessionRestoration_WithStoredCredentials_RestoresSession() async {
        // Store user data in keychain
        let userData = try! JSONEncoder().encode(TestData.testMember)
        try! mockKeychainService.save(key: "currentUser", data: userData)
        let tokenData = "stored-token".data(using: .utf8)!
        try! mockKeychainService.save(key: "accessToken", data: tokenData)

        // Create new view model which should restore session
        let newSut = AuthViewModel(apiClient: mockAPIClient, keychainService: mockKeychainService)

        XCTAssertTrue(newSut.isAuthenticated)
        XCTAssertNotNil(newSut.currentUser)
        XCTAssertEqual(mockAPIClient.accessToken, "stored-token")
    }

    func testSessionRestoration_WithoutStoredCredentials_StaysUnauthenticated() async {
        let newSut = AuthViewModel(apiClient: mockAPIClient, keychainService: mockKeychainService)

        XCTAssertFalse(newSut.isAuthenticated)
        XCTAssertNil(newSut.currentUser)
    }

    // MARK: - Update Current User Tests

    func testUpdateCurrentUser_UpdatesUserAndKeychain() async {
        mockAPIClient.mockResponse = TestData.testLoginResponse
        await sut.login(email: "test@example.com", password: "password123")

        let updatedMember = Member(
            id: "test-user-id",
            firstname: "Updated",
            lastname: "User",
            email: "updated@example.com",
            name: "Updated User",
            street: nil,
            city: nil,
            zipCode: nil,
            phone: nil,
            notificationsEnabled: nil,
            notifyOwnBookings: nil,
            notifyOtherBookings: nil,
            notifyCourtBlocked: nil,
            notifyBookingOverridden: nil,
            emailVerified: nil,
            feePaid: nil,
            paymentConfirmationRequested: nil,
            paymentConfirmationRequestedAt: nil,
            role: nil,
            membershipType: nil,
            isActive: nil
        )

        sut.updateCurrentUser(updatedMember)

        XCTAssertEqual(sut.currentUser?.firstname, "Updated")
        XCTAssertEqual(sut.currentUser?.email, "updated@example.com")
    }
}
