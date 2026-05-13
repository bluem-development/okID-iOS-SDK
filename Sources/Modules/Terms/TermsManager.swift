import Foundation

private let logger = Logger.terms

// MARK: - Terms Manager

/// Manages business logic for terms acceptance
/// Extracted from TermsViewController following proper MVC pattern
/// Handles: API calls for terms acceptance
class TermsManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDTermsModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let apiClient: VerificationAPIClient
    
    // MARK: - Configuration Access
    
    var content: String {
        return config.content
    }
    
    var acceptanceRequired: Bool {
        return config.acceptanceRequired
    }
    
    var buttonTitle: String {
        return config.acceptanceRequired ? "Accept & Continue" : "Continue"
    }
    
    // MARK: - Initialization
    
    init(
        verificationId: String,
        config: OkIDTermsModuleConfig,
        sdkConfig: OkIDSDKConfig
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.apiClient = VerificationAPIClient(config: sdkConfig)
        self.apiClient.setVerificationId(verificationId)
    }
    
    // MARK: - Terms Acceptance
    
    /// Submit terms acceptance to server
    func acceptTerms() async throws -> String? {
        logger.debug("Accepting terms for verification: \(verificationId)")
        
        do {
            let response = try await apiClient.acceptTerms(verificationId: verificationId)
            logger.debug("Terms accepted successfully: \(response.status)")
            return response.nextStep
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "TermsManager.acceptTerms",
                severity: .error
            )
            throw okidError
        }
    }
    
    // MARK: - Validation
    
    /// Check if user can proceed (acceptance checked if required)
    func canProceed(isAccepted: Bool) -> Bool {
        return !acceptanceRequired || isAccepted
    }
}
