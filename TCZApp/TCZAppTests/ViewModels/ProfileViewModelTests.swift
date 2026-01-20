import XCTest
@testable import TCZApp

@MainActor
final class ProfileViewModelTests: XCTestCase {
    var sut: ProfileViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockAPIClient()
        sut = ProfileViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(sut.firstname, "")
        XCTAssertEqual(sut.lastname, "")
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.street, "")
        XCTAssertEqual(sut.city, "")
        XCTAssertEqual(sut.zipCode, "")
        XCTAssertEqual(sut.phone, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.confirmPassword, "")
        XCTAssertTrue(sut.notificationsEnabled)
        XCTAssertTrue(sut.notifyOwnBookings)
        XCTAssertTrue(sut.notifyOtherBookings)
        XCTAssertTrue(sut.notifyCourtBlocked)
        XCTAssertTrue(sut.notifyBookingOverridden)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isSaving)
        XCTAssertFalse(sut.isConfirmingPayment)
        XCTAssertFalse(sut.isUploadingPicture)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.successMessage)
        XCTAssertFalse(sut.hasProfilePicture)
        XCTAssertEqual(sut.profilePictureVersion, 0)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    // MARK: - Load Profile Tests

    func testLoadProfile_Success() async {
        mockAPIClient.mockResponse = TestData.testMember

        await sut.loadProfile(memberId: "test-user-id")

        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.firstname, "Max")
        XCTAssertEqual(sut.lastname, "Mustermann")
        XCTAssertEqual(sut.email, "max@example.com")
        XCTAssertEqual(sut.street, "Teststraße 1")
        XCTAssertEqual(sut.city, "Teststadt")
        XCTAssertEqual(sut.zipCode, "12345")
        XCTAssertEqual(sut.phone, "0123456789")
        XCTAssertTrue(sut.notificationsEnabled)
        XCTAssertTrue(sut.notifyOwnBookings)
        XCTAssertFalse(sut.notifyOtherBookings)
        XCTAssertTrue(sut.notifyCourtBlocked)
        XCTAssertTrue(sut.notifyBookingOverridden)
        XCTAssertTrue(sut.hasProfilePicture)
        XCTAssertEqual(sut.profilePictureVersion, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testLoadProfile_APIError_SetsError() async {
        mockAPIClient.mockError = APIError.unauthorized

        await sut.loadProfile(memberId: "test-user-id")

        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadProfile_GenericError_SetsGenericError() async {
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        await sut.loadProfile(memberId: "test-user-id")

        XCTAssertEqual(sut.error, "Fehler beim Laden des Profils")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Email Validation Tests

    func testValidateEmail_ValidEmail_ReturnsTrue() {
        sut.email = "test@example.com"

        let result = sut.validateEmail()

        XCTAssertTrue(result)
        XCTAssertNil(sut.emailError)
    }

    func testValidateEmail_InvalidEmail_ReturnsFalse() {
        sut.email = "invalid-email"

        let result = sut.validateEmail()

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.emailError)
        XCTAssertEqual(sut.emailError, "Bitte geben Sie eine gültige E-Mail-Adresse ein")
    }

    func testValidateEmail_EmptyEmail_ReturnsFalse() {
        sut.email = ""

        let result = sut.validateEmail()

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.emailError)
    }

    // MARK: - Password Validation Tests

    func testValidatePassword_EmptyPasswords_ReturnsTrue() {
        sut.password = ""
        sut.confirmPassword = ""

        let result = sut.validatePassword()

        XCTAssertTrue(result)
        XCTAssertNil(sut.passwordError)
    }

    func testValidatePassword_TooShort_ReturnsFalse() {
        sut.password = "short"
        sut.confirmPassword = "short"

        let result = sut.validatePassword()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.passwordError, "Das Passwort muss mindestens 8 Zeichen haben")
    }

    func testValidatePassword_Mismatch_ReturnsFalse() {
        sut.password = "password123"
        sut.confirmPassword = "different123"

        let result = sut.validatePassword()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.passwordError, "Die Passwörter stimmen nicht überein")
    }

    func testValidatePassword_ValidMatch_ReturnsTrue() {
        sut.password = "password123"
        sut.confirmPassword = "password123"

        let result = sut.validatePassword()

        XCTAssertTrue(result)
        XCTAssertNil(sut.passwordError)
    }

    // MARK: - Can Save Tests

    func testCanSave_WhenAllRequired_ReturnsTrue() {
        sut.firstname = "Max"
        sut.lastname = "Mustermann"
        sut.email = "max@example.com"

        XCTAssertTrue(sut.canSave)
    }

    func testCanSave_WhenFirstnameEmpty_ReturnsFalse() {
        sut.firstname = ""
        sut.lastname = "Mustermann"
        sut.email = "max@example.com"

        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_WhenLastnameEmpty_ReturnsFalse() {
        sut.firstname = "Max"
        sut.lastname = ""
        sut.email = "max@example.com"

        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_WhenEmailEmpty_ReturnsFalse() {
        sut.firstname = "Max"
        sut.lastname = "Mustermann"
        sut.email = ""

        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_WhenWhitespaceOnly_ReturnsFalse() {
        sut.firstname = "   "
        sut.lastname = "Mustermann"
        sut.email = "max@example.com"

        XCTAssertFalse(sut.canSave)
    }

    // MARK: - Update Profile Tests

    func testUpdateProfile_WithoutMemberId_ReturnsNilWithError() async {
        sut.firstname = "Max"
        sut.lastname = "Mustermann"
        sut.email = "max@example.com"

        let result = await sut.updateProfile()

        XCTAssertNil(result)
        XCTAssertEqual(sut.error, "Benutzer-ID fehlt")
    }

    func testUpdateProfile_WithInvalidEmail_ReturnsNil() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        sut.email = "invalid-email"

        let result = await sut.updateProfile()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.emailError)
    }

    func testUpdateProfile_WithInvalidPassword_ReturnsNil() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        sut.password = "short"
        sut.confirmPassword = "short"

        let result = await sut.updateProfile()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.passwordError)
    }

    func testUpdateProfile_Success() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        let updateResponse = ProfileUpdateResponse(message: "Success", member: TestData.testMember)
        mockAPIClient.mockResponse = updateResponse

        let result = await sut.updateProfile()

        XCTAssertNotNil(result)
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.successMessage, "Profil erfolgreich aktualisiert")
        XCTAssertFalse(sut.isSaving)
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.confirmPassword, "")
    }

    func testUpdateProfile_APIError_ReturnsNilWithError() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        mockAPIClient.mockError = APIError.badRequest("Validation failed")

        let result = await sut.updateProfile()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isSaving)
    }

    func testUpdateProfile_GenericError_ReturnsNilWithGenericError() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        let result = await sut.updateProfile()

        XCTAssertNil(result)
        XCTAssertEqual(sut.error, "Fehler beim Speichern des Profils")
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Confirm Payment Tests

    func testConfirmPayment_Success() async {
        let paymentResponse = PaymentConfirmationResponse(message: "Success", paymentConfirmationRequested: true)
        mockAPIClient.mockResponse = paymentResponse

        let result = await sut.confirmPayment()

        XCTAssertTrue(result)
        XCTAssertTrue(mockAPIClient.requestCalled)
        XCTAssertEqual(sut.successMessage, "Zahlungsbestätigung wurde angefordert")
        XCTAssertFalse(sut.isConfirmingPayment)
    }

    func testConfirmPayment_APIError_ReturnsFalseWithError() async {
        mockAPIClient.mockError = APIError.forbidden("Not allowed")

        let result = await sut.confirmPayment()

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isConfirmingPayment)
    }

    func testConfirmPayment_GenericError_ReturnsFalseWithGenericError() async {
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        let result = await sut.confirmPayment()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.error, "Fehler beim Anfordern der Zahlungsbestätigung")
        XCTAssertFalse(sut.isConfirmingPayment)
    }

    // MARK: - Profile Picture Tests

    func testDeleteProfilePicture_WithoutMemberId_ReturnsNilWithError() async {
        let result = await sut.deleteProfilePicture()

        XCTAssertNil(result)
        XCTAssertEqual(sut.error, "Benutzer-ID fehlt")
    }

    func testDeleteProfilePicture_Success() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        mockAPIClient.mockResponse = TestData.testMember

        let result = await sut.deleteProfilePicture()

        XCTAssertNotNil(result)
        XCTAssertTrue(mockAPIClient.deleteProfilePictureCalled)
        XCTAssertFalse(sut.hasProfilePicture)
        XCTAssertEqual(sut.successMessage, "Profilbild erfolgreich entfernt")
        XCTAssertFalse(sut.isUploadingPicture)
    }

    func testDeleteProfilePicture_APIError_ReturnsNilWithError() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        mockAPIClient.mockError = APIError.notFound

        let result = await sut.deleteProfilePicture()

        XCTAssertNil(result)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isUploadingPicture)
    }

    func testDeleteProfilePicture_GenericError_ReturnsNilWithGenericError() async {
        mockAPIClient.mockResponse = TestData.testMember
        await sut.loadProfile(memberId: "test-user-id")

        mockAPIClient.reset()
        mockAPIClient.mockError = NSError(domain: "Test", code: -1)

        let result = await sut.deleteProfilePicture()

        XCTAssertNil(result)
        XCTAssertEqual(sut.error, "Fehler beim Entfernen des Profilbilds")
        XCTAssertFalse(sut.isUploadingPicture)
    }
}
