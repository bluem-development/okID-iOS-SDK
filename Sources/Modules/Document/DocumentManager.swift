import Foundation
import UIKit
import CoreNFC

private let logger = Logger.document

// MARK: - Document Manager

/// Manages business logic for document capture and upload
/// Extracted from DocumentViewController following proper MVC pattern
/// Handles: validation, API calls, NFC flow, image processing
class DocumentManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDDocumentModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let apiClient: VerificationAPIClient
    private let profileNfcData: OkIDProfileNfcData?
    
    // MARK: - Initialization
    
    init(
        verificationId: String,
        config: OkIDDocumentModuleConfig,
        sdkConfig: OkIDSDKConfig,
        profileNfcData: OkIDProfileNfcData? = nil
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.profileNfcData = profileNfcData
        self.apiClient = VerificationAPIClient(config: sdkConfig)
        self.apiClient.setVerificationId(verificationId)
    }
    
    // MARK: - Document Upload
    
    /// Upload document image to server
    func uploadDocument(
        imageData: Data,
        side: String,
        blurScore: Double?,
        attemptId: String? = nil
    ) async throws -> OkIDDocumentModuleResponse {
        logger.debug("Uploading \(side) side document (blur: \(String(describing: blurScore)))")
        
        do {
            let response = try await apiClient.uploadDocument(
                verificationId: verificationId,
                imageData: imageData,
                side: side,
                blurrinessScore: blurScore,
                attemptId: attemptId
            )
            
            logger.debug("Upload successful: \(response.status)")
            return response
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "DocumentManager.uploadDocument",
                severity: .error
            )
            throw okidError
        }
    }
    
    // MARK: - NFC Availability Check
    
    /// Check if NFC is available on device
    func checkNFCAvailability() -> Bool {
        #if canImport(CoreNFC)
        if #available(iOS 13.0, *) {
            return NFCNDEFReaderSession.readingAvailable
        }
        #endif
        return false
    }
    
    // MARK: - NFC Flow Decision
    
    /// Determine if should proceed to NFC flow based on response
    func shouldProceedToNFC(response: OkIDDocumentModuleResponse, nfcAvailable: Bool) -> Bool {
        logger.debug("========== NFC BRANCH CHECK ==========")
        logger.debug("config.readNfcFromPassport: \(config.readNfcFromPassport)")
        logger.debug("nfcAvailability: \(nfcAvailable)")
        
        guard config.readNfcFromPassport else {
            logger.debug("❌ NFC not enabled in config")
            return false
        }
        
        guard nfcAvailable else {
            logger.debug("❌ NFC not available on device")
            return false
        }
        
        // Check if document has MRZ (indicates passport)
        let rawMrz = response.attemptResult.metrics?.rawMrz
        logger.debug("raw_mrz: \(String(describing: rawMrz))")
        
        let hasMrz = rawMrz != nil && !(rawMrz?.isEmpty ?? true)
        
        if hasMrz {
            logger.info("✓ Document has MRZ - proceeding to NFC")
            return true
        } else {
            logger.debug("❌ No MRZ found - skipping NFC")
            return false
        }
    }
    
    // MARK: - Auto-submit Profile NFC
    
    /// Auto-submit NFC data from profile if available
    func autoSubmitProfileNFC() async throws {
        guard let nfcData = profileNfcData else {
            throw OkIDError.invalidConfiguration(reason: "Profile NFC data not available")
        }
        
        logger.debug("Auto-submitting profile NFC data")
        
        do {
            // Convert profile NFC data to OkIDPassportData
            let passportData = OkIDPassportData(
                personalInfo: convertToPersonalInfo(nfcData.personalInfo),
                photo: nfcData.photo,
                dataGroupsRead: nfcData.dataGroupsRead,
                readAt: Date(timeIntervalSince1970: TimeInterval(nfcData.capturedAt) / 1000)
            )
            
            let metadata: [String: Any] = [
                "read_duration": 0,
                "used_pace": true,
                "source": "profile"
            ]
            
            let _ = try await apiClient.submitNfcData(
                verificationId: verificationId,
                passportData: passportData,
                metadata: metadata,
                photo: nfcData.photo
            )
            
            logger.debug("Profile NFC auto-submit successful")
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "DocumentManager.autoSubmitProfileNFC",
                severity: .error
            )
            throw okidError
        }
    }
    
    /// Convert OkIDProfilePassportInfo to OkIDPersonalInfo
    private func convertToPersonalInfo(_ profileInfo: OkIDProfilePassportInfo) -> OkIDPersonalInfo {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        
        return OkIDPersonalInfo(
            documentType: profileInfo.documentType,
            issuingState: profileInfo.issuingState,
            documentNumber: profileInfo.documentNumber,
            lastName: profileInfo.lastName,
            firstName: profileInfo.firstName,
            nationality: profileInfo.nationality,
            dateOfBirth: profileInfo.dateOfBirth.flatMap { dateFormatter.date(from: $0) },
            gender: profileInfo.gender,
            dateOfExpiry: profileInfo.dateOfExpiry.flatMap { dateFormatter.date(from: $0) },
            optionalData1: profileInfo.optionalData1,
            optionalData2: profileInfo.optionalData2
        )
    }
    
    // MARK: - Submit NFC Data
    
    /// Submit NFC passport data to server
    func submitNFCData(
        passportData: OkIDPassportData,
        readDuration: TimeInterval,
        usedPace: Bool
    ) async throws -> OkIDModuleCompletionResponse {
        logger.debug("Submitting NFC data (duration: \(readDuration)s, PACE: \(usedPace))")
        
        do {
            let metadata: [String: Any] = [
                "read_duration": readDuration,
                "used_pace": usedPace
            ]
            
            let response = try await apiClient.submitNfcData(
                verificationId: verificationId,
                passportData: passportData,
                metadata: metadata,
                photo: passportData.photo
            )
            
            logger.debug("NFC submission successful: \(response.status)")
            return response
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "DocumentManager.submitNFCData",
                severity: .error
            )
            logger.error("NFC submission error: \(okidError.errorDescription ?? error.localizedDescription)")
            
            // Even if NFC submission fails, we don't block the flow
            throw okidError
        }
    }
    
    // MARK: - MRZ Extraction
    
    /// Extract MRZ credentials from document response
    func extractMRZCredentials(from response: OkIDDocumentModuleResponse) -> OkIDPassportCredentials? {
        guard let rawMrz = response.attemptResult.metrics?.rawMrz,
              !rawMrz.isEmpty else {
            logger.debug("No MRZ found in response")
            return nil
        }
        
        logger.debug("Extracting MRZ from raw data")
        
        // Parse MRZ lines
        let mrzLines = rawMrz.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        
        guard mrzLines.count >= 2 else {
            logger.debug("Insufficient MRZ lines")
            return nil
        }
        
        // Parse MRZ using MRZParser
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        
        // TD3 format (passport) - 2 lines of 44 characters
        if mrzLines.count == 2 && mrzLines[0].count == 44 && mrzLines[1].count == 44 {
            let line2 = mrzLines[1]
            
            // Extract fields from line 2
            let documentNumber = String(line2.prefix(9)).trimmingCharacters(in: CharacterSet(charactersIn: "<"))
            let dobString = String(line2.dropFirst(13).prefix(6))
            let expiryString = String(line2.dropFirst(21).prefix(6))
            
            guard let dob = dateFormatter.date(from: dobString),
                  let expiry = dateFormatter.date(from: expiryString) else {
                logger.debug("Failed to parse MRZ dates")
                return nil
            }
            
            let credentials = OkIDPassportCredentials(
                documentNumber: documentNumber,
                dateOfBirth: dob,
                dateOfExpiry: expiry
            )
            
            logger.debug("MRZ parsed successfully")
            return credentials
        }
        
        logger.debug("Failed to parse MRZ - unsupported format")
        return nil
    }
    
    // MARK: - Error Analysis
    
    /// Analyze error message and provide user-friendly tips
    func analyzeError(_ message: String) -> (title: String, message: String, tips: [String]) {
        if message.contains("BLURRY") || message.contains("QUALITY") {
            return (
                title: "Image Quality Issue",
                message: "The document image is too blurry",
                tips: [
                    "Use bright, even lighting",
                    "Hold camera steady",
                    "Clean your camera lens",
                    "Avoid shadows on document"
                ]
            )
        } else if message.contains("NO_DOCUMENT") {
            return (
                title: "No Document Detected",
                message: "Could not find a document in the image",
                tips: [
                    "Fill the entire frame with document",
                    "Ensure document is fully visible",
                    "Place document on contrasting background",
                    "Avoid reflective surfaces"
                ]
            )
        } else if message.contains("GLARE") || message.contains("REFLECTION") {
            return (
                title: "Glare Detected",
                message: "Reflections or glare detected on document",
                tips: [
                    "Avoid direct light on document",
                    "Tilt document to reduce glare",
                    "Remove from plastic sleeve",
                    "Use diffused lighting"
                ]
            )
        } else {
            return (
                title: "Upload Failed",
                message: message,
                tips: [
                    "Check your internet connection",
                    "Ensure good lighting",
                    "Hold camera steady",
                    "Try again"
                ]
            )
        }
    }
    
    // MARK: - Validation
    
    /// Validate document quality before upload
    func validateDocumentQuality(imageData: Data) -> Bool {
        // Basic validation - image data exists and is not empty
        guard !imageData.isEmpty else {
            return false
        }
        
        // Additional validation can be added here
        // (e.g., minimum image size, format check, etc.)
        
        return true
    }
}
