import Foundation
@testable import TCZApp

final class MockKeychainService: KeychainServiceProtocol {
    var storage: [String: Data] = [:]

    // Track method calls
    var saveCalled = false
    var loadCalled = false
    var deleteCalled = false
    var lastSaveKey: String?
    var lastLoadKey: String?
    var lastDeleteKey: String?

    // Mock behavior
    var shouldFailOnSave = false

    func save(key: String, data: Data) throws {
        saveCalled = true
        lastSaveKey = key

        if shouldFailOnSave {
            throw KeychainError.saveFailed(-1)
        }

        storage[key] = data
    }

    func load(key: String) -> Data? {
        loadCalled = true
        lastLoadKey = key
        return storage[key]
    }

    func delete(key: String) {
        deleteCalled = true
        lastDeleteKey = key
        storage.removeValue(forKey: key)
    }

    // Helper to reset state between tests
    func reset() {
        storage.removeAll()
        saveCalled = false
        loadCalled = false
        deleteCalled = false
        lastSaveKey = nil
        lastLoadKey = nil
        lastDeleteKey = nil
        shouldFailOnSave = false
    }
}
