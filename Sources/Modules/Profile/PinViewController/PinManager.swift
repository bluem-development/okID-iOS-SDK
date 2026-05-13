import Foundation
import Security
import CryptoKit

/// Manages PIN storage and verification using Keychain
public class PinManager {
    
    private static let pinHashKey = "identity_vault_pin_hash"
    private static let pinEnabledKey = "identity_vault_pin_enabled"
    private static let serviceName = "com.okid.verification.pin"
    
    /// Check if PIN is enabled
    public static func isPinEnabled() async -> Bool {
        return await KeychainService.shared.read(key: pinEnabledKey) == "true"
    }
    
    /// Set up a new PIN
    public static func setPin(_ pin: String) async throws {
        let hash = hashPin(pin)
        try await KeychainService.shared.save(hash, for: pinHashKey)
        try await KeychainService.shared.save("true", for: pinEnabledKey)
    }
    
    /// Verify a PIN
    public static func verifyPin(_ pin: String) async -> Bool {
        guard let storedHash = await KeychainService.shared.read(key: pinHashKey) else {
            return false
        }
        
        let inputHash = hashPin(pin)
        return storedHash == inputHash
    }
    
    /// Delete PIN (disable protection)
    public static func deletePin() async throws {
        try await KeychainService.shared.delete(key: pinHashKey)
        try await KeychainService.shared.delete(key: pinEnabledKey)
    }
    
    /// Hash PIN using SHA-256
    private static func hashPin(_ pin: String) -> String {
        let inputData = Data(pin.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Simple Keychain service for PIN storage
actor KeychainService {
    
    static let shared = KeychainService()
    
    private init() {}
    
    func save(_ value: String, for key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.okid.verification",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.okid.verification",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.okid.verification"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToDelete
    case itemNotFound
}

