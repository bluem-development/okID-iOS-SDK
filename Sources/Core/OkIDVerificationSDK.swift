import Foundation
import UIKit

/// Main SDK entry point for OkID Verification
@MainActor
public class OkIDVerificationSDK {
    
    /// SDK version
    public static let version = "1.0.0"
    private var errorMessage: String?
    
    /// Shared instance
    public static let shared = OkIDVerificationSDK()
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Enable or disable debug logging
    /// - Parameter enabled: true to enable logging, false to disable
    public static func setLoggingEnabled(_ enabled: Bool) {
        Logger.isEnabled = enabled
    }
    
    /// Check if logging is enabled
    /// - Returns: true if logging is enabled
    public static func isLoggingEnabled() -> Bool {
        return Logger.isEnabled
    }
    
    // MARK: - Verification Flow
    
    /// Start verification flow
    /// - Parameters:
    ///   - verificationId: The verification ID from backend
    ///   - config: SDK configuration
    ///   - from: Presenting view controller
    ///   - flow: Optional custom flow order
    ///   - modules: Optional module configurations
    ///   - callbacks: Optional callbacks for verification events
    public func startVerification(
        verificationId: String,
        config: OkIDSDKConfig,
        from viewController: UIViewController,
        flow: [String]? = nil,
        modules: [String: Any]? = nil,
        callbacks: OkIDVerificationCallbacks? = nil
    ) async {
        // Apply logging configuration
        Logger.isEnabled = config.enableLogging
        
        let flowController = VerificationFlowController(
            verificationId: verificationId,
            config: config,
            callbacks: callbacks,
            initialFlow: flow,
            initialModules: modules
        )
        
        let navController = UINavigationController(rootViewController: flowController)
        navController.modalPresentationStyle = .fullScreen
        await viewController.present(navController, animated: true)
    }
    
    /// Start verification and return result
    /// - Parameters:
    ///   - verificationId: The verification ID from backend
    ///   - config: SDK configuration
    ///   - from: Presenting view controller
    ///   - flow: Optional custom flow order
    ///   - modules: Optional module configurations
    ///   - desktopSessionId: Optional desktop session ID for notifications
    ///   - portalBaseUrl: Optional portal base URL for desktop notifications
    /// - Returns: Verification result or nil if cancelled
    public func startVerificationForResult(
        verificationId: String,
        config: OkIDSDKConfig,
        from viewController: UIViewController,
        flow: [String]? = nil,
        modules: [String: Any]? = nil,
        desktopSessionId: String? = nil,
        portalBaseUrl: String? = nil
    ) async -> OkIDVerificationResult? {
        // Apply logging configuration
        Logger.isEnabled = config.enableLogging
        
        return await withCheckedContinuation { continuation in
            let callbacks = ResultCallbacks(continuation: continuation)
            
            let flowController = VerificationFlowController(
                verificationId: verificationId,
                config: config,
                callbacks: callbacks,
                initialFlow: flow,
                initialModules: modules,
                desktopSessionId: desktopSessionId,
                portalBaseUrl: portalBaseUrl
            )
            
            let navController = UINavigationController(rootViewController: flowController)
            navController.modalPresentationStyle = .fullScreen
            viewController.present(navController, animated: true)
        }
    }
    
    // MARK: - QR Code Scanning
    
    /// Scan QR code from v2client portal
    /// - Parameters:
    ///   - from: Presenting view controller
    ///   - primaryColor: Primary color for UI
    ///   - allowedOrigins: Optional list of allowed portal origins
    /// - Returns: QR scan result or nil if cancelled
    public func scanQRCode(
        from viewController: UIViewController,
        primaryColor: UIColor? = nil,
        allowedOrigins: [String]? = nil
    ) async -> OkIDQRScanResult? {
        let color = primaryColor ?? .okidPrimary
        return await withCheckedContinuation { continuation in
            let scanner = QRScannerViewController(
                primaryColor: color,
                allowedOrigins: allowedOrigins
            ) { result in
                viewController.dismiss(animated: true)
                continuation.resume(returning: result)
            }
            
            let navigationController = UINavigationController(rootViewController: scanner)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        }
    }
    
    /// Start verification from scanned QR code
    /// - Parameters:
    ///   - from: Presenting view controller
    ///   - config: SDK configuration
    ///   - allowedOrigins: Optional list of allowed portal origins
    /// - Returns: Verification result or nil if cancelled
    public func startFromQRCode(
        from viewController: UIViewController,
        config: OkIDSDKConfig,
        allowedOrigins: [String]? = nil
    ) async -> OkIDVerificationResult? {
        // Apply logging configuration
        Logger.isEnabled = config.enableLogging
        
        // Step 1: Scan QR code
        guard let scanResult = await scanQRCode(
            from: viewController,
            primaryColor: config.theme.colors.primary,
            allowedOrigins: allowedOrigins
        ) else {
            return nil
        }
        
        var verificationId: String
        var flow: [String]?
        var modules: [String: Any]?
        
        // Step 2: Get or generate verification ID
        if scanResult.isGenerateFlow {
            let apiClient = VerificationAPIClient(config: config)
            do {
                let response = try await apiClient.generateVerification(portalBaseUrl: scanResult.origin)
                verificationId = response.verificationId
                flow = response.flow
                modules = response.modules
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
                return nil
            }
        } else {
            verificationId = scanResult.verificationId ?? ""
        }
        
        // Step 3: Notify desktop of mobile access
        if let desktopSessionId = scanResult.desktopSessionId {
            let notifier = DesktopNotifier(
                portalBaseUrl: scanResult.origin,
                desktopSessionId: desktopSessionId
            )
            try? await notifier.notifyMobileAccess(verificationId: verificationId)
        }
        
        // Step 4: Start verification flow
        return await startVerificationForResult(
            verificationId: verificationId,
            config: config,
            from: viewController,
            flow: flow,
            modules: modules,
            desktopSessionId: scanResult.desktopSessionId,
            portalBaseUrl: scanResult.origin
        )
    }
    
    // MARK: - Profile Management
    
    /// Open profile management dashboard
    /// - Parameters:
    ///   - from: Presenting view controller
    ///   - config: SDK configuration
    /// - Returns: Profile result indicating if profile was modified
    public func manageProfile(
        from viewController: UIViewController,
        config: OkIDSDKConfig
    ) async -> OkIDProfileResult? {
        // Apply logging configuration
        Logger.isEnabled = config.enableLogging
        
        return await withCheckedContinuation { continuation in
            let dashboard = ProfileDashboardViewController(config: config) { result in
                viewController.dismiss(animated: true)
                continuation.resume(returning: result)
            }
            
            // Present as full-screen modal directly (no navigation controller wrapper)
            dashboard.modalPresentationStyle = .fullScreen
            
            viewController.present(dashboard, animated: true)
        }
    }
    
    /// Get current profile status
    /// - Parameter freshnessThreshold: Duration for data freshness
    /// - Returns: Profile status
    public func getProfileStatus(
        freshnessThreshold: TimeInterval = 60 * 24 * 60 * 60 // 60 days
    ) async -> OkIDProfileStatus {
        let storage = ProfileStorageService(freshnessThreshold: freshnessThreshold)
        return await storage.getStatus()
    }
    
    /// Check if profile exists
    /// - Returns: True if profile exists
    public func hasProfile() async -> Bool {
        let storage = ProfileStorageService()
        return await storage.exists()
    }
    
    /// Delete stored profile
    public func deleteProfile() async {
        let storage = ProfileStorageService()
        await storage.deleteProfile()
    }
    
    /// Load full profile data
    /// - Parameter freshnessThreshold: Duration for data freshness
    /// - Returns: Verification profile or nil
    public func loadProfile(
        freshnessThreshold: TimeInterval = 60 * 24 * 60 * 60 // 60 days
    ) async -> OkIDVerificationProfile? {
        let storage = ProfileStorageService(freshnessThreshold: freshnessThreshold)
        return await storage.loadProfile()
    }
    
    // MARK: - NFC Module

    /// Open NFC passport reader module standalone
    /// - Parameters:
    ///   - from: Presenting view controller
    ///   - config: SDK configuration
    /// - Returns: Passport data read from the chip, or nil if cancelled or failed
    public func openNfcModule(
        from viewController: UIViewController,
        config: OkIDSDKConfig
    ) async -> OkIDPassportData? {
        await withCheckedContinuation { continuation in
            openNfcModule(from: viewController, config: config) { passportData in
                continuation.resume(returning: passportData)
            }
        }
    }

    /// Open NFC passport reader module standalone (callback-based)
    /// - Parameters:
    ///   - from: Presenting view controller
    ///   - config: SDK configuration
    ///   - completion: Completion handler called when NFC reading finishes
    public func openNfcModule(
        from viewController: UIViewController,
        config: OkIDSDKConfig,
        completion: @escaping (OkIDPassportData?) -> Void
    ) {
        // Apply logging configuration
        Logger.isEnabled = config.enableLogging
        
        let nfcInput = NFCInputViewController(
            onStart: { credentials in
                // User wants to start NFC reading
                let nfcReading = NFCReadingViewController(
                    credentials: credentials,
                    primaryColor: config.theme.colors.primary,
                    onSuccess: { passportData in
                        viewController.dismiss(animated: true) {
                            completion(passportData)
                        }
                    },
                    onError: { error in
                        viewController.dismiss(animated: true) {
                            completion(nil)
                        }
                    },
                    onCancel: {
                        viewController.dismiss(animated: true) {
                            completion(nil)
                        }
                    }
                )
                
                if let navController = viewController.presentedViewController as? UINavigationController {
                    navController.pushViewController(nfcReading, animated: true)
                }
            },
            onCancel: {
                viewController.dismiss(animated: true) {
                    completion(nil)
                }
            },
            primaryColor: config.theme.colors.primary
        )
        
        let navController = UINavigationController(rootViewController: nfcInput)
        navController.modalPresentationStyle = .fullScreen
        viewController.present(navController, animated: true)
    }
}

// MARK: - Result Callbacks

private class ResultCallbacks: OkIDVerificationCallbacks {
    private let continuation: CheckedContinuation<OkIDVerificationResult?, Never>
    private var hasResumed = false
    private let lock = NSLock()
    
    init(continuation: CheckedContinuation<OkIDVerificationResult?, Never>) {
        self.continuation = continuation
    }
    
    deinit {
        // Ensure continuation is always resumed, even if callbacks never called
        resumeIfNeeded(with: nil)
    }
    
    func onModuleComplete(module: String, status: String) {
        // No-op
    }
    
    func onVerificationComplete(result: OkIDVerificationResult) {
        resumeIfNeeded(with: result)
    }
    
    func onError(error: String) {
        // Resume with nil on error
        resumeIfNeeded(with: nil)
    }
    
    func onCancel() {
        resumeIfNeeded(with: nil)
    }
    
    private func resumeIfNeeded(with result: OkIDVerificationResult?) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(returning: result)
    }
}

