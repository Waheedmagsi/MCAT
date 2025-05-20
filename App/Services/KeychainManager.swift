import Foundation
import Security

/// Manages secure storage of sensitive data using the iOS Keychain
class KeychainManager {
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
    }
    
    static func save(key: String, data: String) throws {
        // Convert string to data
        guard let encodedData = data.data(using: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecParam)
        }
        
        // Create dictionary of keychain attributes
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static func retrieve(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = item as? Data,
              let result = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecInternalError)
        }
        
        return result
    }
    
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
} 