import Foundation
@testable import TCZApp

final class MockAPIClient: APIClientProtocol {
    var accessToken: String?
    var onUnauthorizedHandler: (() -> Void)?

    // Track method calls
    var requestCalled = false
    var requestVoidCalled = false
    var lastEndpoint: APIEndpoint?
    var lastBody: Encodable?

    // Mock responses
    var mockResponse: Any?
    var mockError: Error?

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: Encodable?) async throws -> T {
        requestCalled = true
        lastEndpoint = endpoint
        lastBody = body

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw APIError.invalidResponse
        }

        return response
    }

    func requestVoid(_ endpoint: APIEndpoint, body: Encodable?) async throws {
        requestVoidCalled = true
        lastEndpoint = endpoint
        lastBody = body

        if let error = mockError {
            throw error
        }
    }

    func setAccessToken(_ token: String?) {
        accessToken = token
    }

    func clearAuth() {
        accessToken = nil
    }

    func setOnUnauthorized(_ handler: @escaping () -> Void) {
        onUnauthorizedHandler = handler
    }

    // MARK: - Profile Picture Methods

    var mockProfilePictureResponse: ProfilePictureResponse?
    var mockProfilePictureData: Data?
    var uploadProfilePictureCalled = false
    var fetchProfilePictureCalled = false
    var deleteProfilePictureCalled = false

    func uploadProfilePicture(memberId: String, imageData: Data) async throws -> ProfilePictureResponse {
        uploadProfilePictureCalled = true
        if let error = mockError {
            throw error
        }
        return mockProfilePictureResponse ?? ProfilePictureResponse(message: "Success", hasProfilePicture: true, profilePictureVersion: 1)
    }

    func fetchProfilePicture(memberId: String) async throws -> Data {
        fetchProfilePictureCalled = true
        if let error = mockError {
            throw error
        }
        return mockProfilePictureData ?? Data()
    }

    func deleteProfilePicture(memberId: String) async throws {
        deleteProfilePictureCalled = true
        if let error = mockError {
            throw error
        }
    }

    // Helper to reset state between tests
    func reset() {
        accessToken = nil
        onUnauthorizedHandler = nil
        requestCalled = false
        requestVoidCalled = false
        lastEndpoint = nil
        lastBody = nil
        mockResponse = nil
        mockError = nil
        mockProfilePictureResponse = nil
        mockProfilePictureData = nil
        uploadProfilePictureCalled = false
        fetchProfilePictureCalled = false
        deleteProfilePictureCalled = false
    }
}
