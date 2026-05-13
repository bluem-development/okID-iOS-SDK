import Foundation
import Security

private let logger = Logger.storage

/// Profile storage service with encryption
public actor ProfileStorageService {
    
    private let freshnessThreshold: TimeInterval
    private static let profileKey = "okid_verification_profile"
    private static let serviceName = "com.okid.verification.profile"
    
    public init(freshnessThreshold: TimeInterval = 60 * 24 * 60 * 60) { // 60 days
        self.freshnessThreshold = freshnessThreshold
    }
    
    // MARK: - Status Methods
    
    public func getStatus() async -> OkIDProfileStatus {
        guard let profile = await loadProfile() else {
            return .empty
        }
        
        return profile.getStatus(freshnessThreshold: freshnessThreshold)
    }
    
    public func exists() async -> Bool {
        return await loadProfile() != nil
    }
    
    // MARK: - Load Profile
    
    public func loadProfile() async -> OkIDVerificationProfile? {
        guard let data = loadFromKeychain() else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(OkIDVerificationProfile.self, from: data)
        } catch {
            logger.error("Failed to decode profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Save Profile
    
    public func saveProfile(_ profile: OkIDVerificationProfile) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        guard saveToKeychain(data: data) else {
            throw ProfileStorageError.saveFailed
        }
    }
    
    // MARK: - Delete Profile
    
    public func deleteProfile() async {
        deleteFromKeychain()
    }
    
    // MARK: - Update Module
    
    /// Update a specific module in the profile
    public func updateModule(
        document: OkIDProfileDocumentData? = nil,
        liveness: OkIDProfileLivenessData? = nil,
        nfc: OkIDProfileNfcData? = nil
    ) async throws {
        var profile = await loadProfile() ?? OkIDVerificationProfile()
        
        profile = profile.copyWith(
            document: document,
            liveness: liveness,
            nfc: nfc
        )
        
        try await saveProfile(profile)
    }
    
    // MARK: - Keychain Operations
    
    private func loadFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.profileKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    private func saveToKeychain(data: Data) -> Bool {
        // Try to update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.profileKey
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If update failed because item doesn't exist, add it
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        return status == errSecSuccess
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.profileKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Storage Error

public enum ProfileStorageError: Error, LocalizedError {
    case saveFailed
    case loadFailed
    case decodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save profile"
        case .loadFailed:
            return "Failed to load profile"
        case .decodingFailed:
            return "Failed to decode profile data"
        }
    }
}

