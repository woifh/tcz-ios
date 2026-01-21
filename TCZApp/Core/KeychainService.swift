import Foundation
import Security

protocol KeychainServiceProtocol {
    func save(key: String, data: Data) throws
    func load(key: String) -> Data?
    func delete(key: String)
}

final class KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private let service = "com.tcz.tennisapp"

    private init() {}

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item first
        let deleteStatus = SecItemDelete(query as CFDictionary)
        // Only errSecItemNotFound is acceptable (item didn't exist)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            #if DEBUG
            print("Warning: Failed to delete existing keychain item before save: \(deleteStatus)")
            #endif
        }

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            #if DEBUG
            if status != errSecItemNotFound {
                print("Keychain load failed with status: \(status)")
            }
            #endif
            return nil
        }

        return result as? Data
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Warning: Keychain delete failed with status: \(status)")
        }
        #endif
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed with status: \(status)"
        case .loadFailed(let status):
            return "Keychain load failed with status: \(status)"
        case .deleteFailed(let status):
            return "Keychain delete failed with status: \(status)"
        }
    }
}
