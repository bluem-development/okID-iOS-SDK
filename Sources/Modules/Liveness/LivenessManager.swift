import Foundation
import UIKit

private let logger = Logger.liveness

// MARK: - Liveness Manager

/// Manages business logic for liveness capture and upload
/// Extracted from LivenessViewController following proper MVC pattern
/// Handles: validation, API calls, biometric processing
class LivenessManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDLivenessModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let apiClient: VerificationAPIClient
    
    // MARK: - Initialization
    
    init(
        verificationId: String,
        config: OkIDLivenessModuleConfig,
        sdkConfig: OkIDSDKConfig
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.apiClient = VerificationAPIClient(config: sdkConfig)
        self.apiClient.setVerificationId(verificationId)
    }
    
    // MARK: - Image Upload
    
    /// Upload selfie image to server
    func uploadSelfie(
        imageData: Data,
        biometricData: [String: Any]?
    ) async throws -> OkIDModuleCompletionResponse {
        logger.debug("Uploading selfie (size: \(imageData.count) bytes)")
        
        do {
            let response = try await apiClient.uploadSelfie(
                verificationId: verificationId,
                imageData: imageData,
                biometricData: biometricData
            )
            
            logger.debug("Upload successful: \(response.status)")
            return response
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "LivenessManager.uploadSelfie",
                severity: .error
            )
            throw okidError
        }
    }
    
    // MARK: - Validation
    
    /// Validate captured image quality
    func validateImageQuality(imageData: Data) -> Bool {
        // Basic validation
        guard !imageData.isEmpty else {
            logger.warning("Image data is empty")
            return false
        }
        
        // Check minimum size
        guard imageData.count > 10000 else { // ~10KB minimum
            logger.warning("Image too small: \(imageData.count) bytes")
            return false
        }
        
        return true
    }
    
    /// Validate biometric data if present
    func validateBiometricData(_ data: [String: Any]?) -> Bool {
        guard let data = data else {
            return true // Biometric data is optional
        }
        
        // Check for required fields if biometric data is provided
        // This could be extended based on requirements
        return true
    }
}
