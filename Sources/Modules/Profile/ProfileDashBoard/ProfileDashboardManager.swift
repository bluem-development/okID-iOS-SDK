import UIKit
import Foundation

private let logger = Logger.profile

// MARK: - Profile Dashboard Manager

/// Manages business logic for the profile dashboard
/// Extracted from ProfileDashboardViewController following proper MVC pattern
/// Handles: status loading, security level calculation, PIN management, module saving, deletion
class ProfileDashboardManager {
    
    // MARK: - Properties
    
    private let config: OkIDSDKConfig
    
    // Status colors
    let colorNone = UIColor.okidGrayNone
    let colorFresh = UIColor.okidSuccess
    let colorOutdated = UIColor.okidWarning
    
    var primaryColor: UIColor {
        return config.theme.colors.primary
    }
    
    // MARK: - Initialization
    
    init(config: OkIDSDKConfig) {
        self.config = config
    }
    
    // MARK: - Storage Access
    
    private var storage: ProfileStorageService {
        return ProfileStorageService(freshnessThreshold: config.profileFreshnessThreshold)
    }
    
    // MARK: - Status Loading
    
    /// Load profile status from storage
    func loadProfileStatus() async -> OkIDProfileStatus {
        let status = await storage.getStatus()
        logger.debug("Profile status loaded: doc=\(status.document), liveness=\(status.liveness), nfc=\(status.nfc)")
        return status
    }
    
    /// Load full profile from storage (for previews)
    func loadProfile() async -> OkIDVerificationProfile? {
        return await storage.loadProfile()
    }
    
    // MARK: - PIN Management
    
    /// Check if PIN is enabled
    func checkPinEnabled() async -> Bool {
        return await PinManager.isPinEnabled()
    }
    
    /// Delete PIN
    func deletePin() async {
        try? await PinManager.deletePin()
    }
    
    // MARK: - Module Data Saving
    
    /// Save document capture data
    func saveDocumentData(_ data: OkIDProfileDocumentData) async throws {
        try await storage.updateModule(document: data)
        logger.debug("Document data saved to profile")
    }
    
    /// Save liveness capture data
    func saveLivenessData(_ data: OkIDProfileLivenessData) async throws {
        try await storage.updateModule(liveness: data)
        logger.debug("Liveness data saved to profile")
    }
    
    /// Save NFC capture data
    func saveNfcData(_ data: OkIDProfileNfcData) async throws {
        try await storage.updateModule(nfc: data)
        logger.debug("NFC data saved to profile")
    }
    
    /// Delete entire profile
    func deleteProfile() async {
        await OkIDVerificationSDK.shared.deleteProfile()
        try? await PinManager.deletePin()
        logger.debug("Profile and PIN deleted")
    }
    
    // MARK: - Security Level Calculation
    
    /// Calculate security level based on profile status (0-3)
    func calculateSecurityLevel(from status: OkIDProfileStatus) -> Int {
        let hasDocument = status.document == .fresh
        let hasLiveness = status.liveness == .fresh
        let hasNfc = status.nfc == .fresh
        
        if hasDocument && hasLiveness && hasNfc { return 3 }
        if hasDocument && hasLiveness { return 2 }
        if hasDocument { return 1 }
        return 0
    }
    
    /// Get display info for a security level
    func getSecurityLevelInfo(level: Int) -> (title: String, description: String, color: UIColor) {
        switch level {
        case 3:
            return (
                "Maximum Security",
                "Document + Biometric + Chip verification",
                primaryColor
            )
        case 2:
            return (
                "High Security",
                "Document + Biometric verification",
                primaryColor
            )
        case 1:
            return (
                "Basic Security",
                "Document verification only",
                colorOutdated
            )
        default:
            return (
                "No Security Level",
                "Capture your ID document to begin",
                colorNone
            )
        }
    }
    
    // MARK: - Status Helpers
    
    /// Get color for a module status
    func getStatusColor(_ status: OkIDProfileModuleStatus) -> UIColor {
        switch status {
        case .none: return colorNone
        case .fresh: return colorFresh
        case .outdated: return colorOutdated
        }
    }
    
    /// Get descriptive text for a module status
    func getStatusText(_ status: OkIDProfileModuleStatus, capturedAt: Int64?) -> String {
        switch status {
        case .none:
            return "Not captured"
        case .fresh, .outdated:
            guard let capturedAt = capturedAt else { return "Captured" }
            let captured = Date(timeIntervalSince1970: TimeInterval(capturedAt) / 1000)
            let now = Date()
            let difference = Calendar.current.dateComponents([.day, .weekOfYear, .month], from: captured, to: now)
            
            if let days = difference.day {
                if days == 0 {
                    return "Captured today"
                } else if days == 1 {
                    return "Captured yesterday"
                } else if days < 7 {
                    return "Captured \(days) days ago"
                } else if let weeks = difference.weekOfYear, weeks < 4 {
                    return "Captured \(weeks) week\(weeks == 1 ? "" : "s") ago"
                } else if let months = difference.month, months > 0 {
                    return status == .outdated
                        ? "Outdated (\(months) month\(months == 1 ? "" : "s"))"
                        : "Captured \(months) month\(months == 1 ? "" : "s") ago"
                }
            }
            return "Captured"
        }
    }
    
    // MARK: - Capture Coordinators
    
    /// Create document capture coordinator
    func createDocumentCapture(completion: @escaping (OkIDProfileDocumentData?) -> Void) -> UIViewController {
        return ProfileCaptureCoordinator.documentCapture(config: config, completion: completion)
    }
    
    /// Create liveness capture coordinator
    func createLivenessCapture(completion: @escaping (OkIDProfileLivenessData?) -> Void) -> UIViewController {
        return ProfileCaptureCoordinator.livenessCapture(config: config, completion: completion)
    }
    
    /// Create NFC capture coordinator
    func createNfcCapture(completion: @escaping (OkIDProfileNfcData?) -> Void) -> UIViewController {
        return ProfileCaptureCoordinator.nfcCapture(config: config, completion: completion)
    }
}
