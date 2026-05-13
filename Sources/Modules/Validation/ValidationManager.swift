import Foundation

private let logger = Logger.validation

// MARK: - Validation Manager

/// Manages business logic for verification validation
/// Extracted from ValidationViewController following proper MVC pattern
/// Handles: API calls, validation status interpretation
class ValidationManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let sdkConfig: OkIDSDKConfig
    private let apiClient: VerificationAPIClient
    
    // MARK: - Initialization
    
    init(verificationId: String, sdkConfig: OkIDSDKConfig) {
        self.verificationId = verificationId
        self.sdkConfig = sdkConfig
        self.apiClient = VerificationAPIClient(config: sdkConfig)
        self.apiClient.setVerificationId(verificationId)
    }
    
    // MARK: - Validation
    
    /// Validate verification and return result
    func validateVerification() async throws -> OkIDValidationResponse {
        logger.debug("Starting validation for verification: \(verificationId)")
        
        do {
            let response = try await apiClient.validateVerification(verificationId: verificationId)
            logger.debug("Validation completed with status: \(response.status)")
            return response
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "ValidationManager.validateVerification",
                severity: .error
            )
            throw okidError
        }
    }
    
    // MARK: - Status Interpretation
    
    /// Convert API status to app state
    func interpretStatus(_ status: String) -> ValidationModuleState {
        switch status {
        case "verified":
            return .success
        case "needs_manual_review":
            return .needsReview
        case "rejected":
            return .rejected
        default:
            return .success // Treat unknown as success
        }
    }
}
