import Foundation
import UIKit

private let logger = Logger.flow

// MARK: - Verification Flow Manager

/// Manages business logic for the verification flow
/// Handles: initialization, profile loading, auto-submit, config parsing,
/// desktop notifications, module completion
class VerificationFlowManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let sdkConfig: OkIDSDKConfig
    private let callbacks: OkIDVerificationCallbacks?
    private let initialFlow: [String]?
    private let initialModules: [String: Any]?
    private let desktopSessionId: String?
    private let portalBaseUrl: String?
    
    private let state: VerificationFlowState
    private var profileStorage: ProfileStorageService?
    private var desktopNotifier: DesktopNotifier?
    
    // MARK: - Initialization
    
    init(
        verificationId: String,
        sdkConfig: OkIDSDKConfig,
        callbacks: OkIDVerificationCallbacks?,
        initialFlow: [String]?,
        initialModules: [String: Any]?,
        desktopSessionId: String?,
        portalBaseUrl: String?,
        state: VerificationFlowState
    ) {
        self.verificationId = verificationId
        self.sdkConfig = sdkConfig
        self.callbacks = callbacks
        self.initialFlow = initialFlow
        self.initialModules = initialModules
        self.desktopSessionId = desktopSessionId
        self.portalBaseUrl = portalBaseUrl
        self.state = state
    }
    
    // MARK: - Setup
    
    func initializeDesktopNotifier() {
        if let desktopSessionId = desktopSessionId, let portalBaseUrl = portalBaseUrl {
            desktopNotifier = DesktopNotifier(
                portalBaseUrl: portalBaseUrl,
                desktopSessionId: desktopSessionId
            )
        }
    }
    
    func cleanupNotifier() {
        desktopNotifier = nil
    }
    
    // MARK: - Profile Initialization
    
    func loadProfileThenInitialize() async {
        await initializeProfile()
        await initializeVerification()
    }
    
    private func initializeProfile() async {
        profileStorage = ProfileStorageService(
            freshnessThreshold: sdkConfig.profileFreshnessThreshold
        )
        
        do {
            state.profileStatus = await profileStorage?.getStatus()
            
            if state.profileStatus?.hasAnyFreshData == true {
                state.profile = await profileStorage?.loadProfile()
                logger.info("Profile loaded with fresh data")
                logger.debug("Document: \(String(describing: state.profileStatus?.document))")
                logger.debug("Liveness: \(String(describing: state.profileStatus?.liveness))")
                logger.debug("NFC: \(String(describing: state.profileStatus?.nfc))")
            }
        } catch {
            logger.error("Error loading profile: \(error)")
        }
    }
    
    // MARK: - Verification Initialization
    
    func initializeVerification() async {
        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
        }
        
        logger.debug("========== INITIALIZATION ==========")
        logger.debug("verificationId: \(verificationId)")
        logger.debug("initialFlow provided: \(initialFlow != nil)")
        logger.debug("initialModules provided: \(initialModules != nil)")
        
        do {
            if let initialFlow = initialFlow, let initialModules = initialModules {
                logger.debug("Using provided flow and modules")
                
                await MainActor.run {
                    self.state.flow = initialFlow
                    self.state.modules = initialModules
                    self.state.currentModule = initialFlow.first ?? "terms"
                    self.state.isLoading = false
                }
                
                let apiClient = VerificationAPIClient(config: sdkConfig)
                apiClient.setVerificationId(verificationId)
                _ = try await apiClient.startVerification(verificationId: verificationId, locale: sdkConfig.locale)
                
                logger.debug("====================================")
                return
            }
            
            logger.debug("No initial data, using defaults")
            let apiClient = VerificationAPIClient(config: sdkConfig)
            apiClient.setVerificationId(verificationId)
            
            let response = try await apiClient.startVerification(
                verificationId: verificationId,
                locale: sdkConfig.locale
            )
            
            await MainActor.run {
                self.state.flow = ["terms", "document", "liveness", "form_data", "validation"]
                self.state.modules = [:]
                self.state.currentModule = response.nextStep ?? self.state.flow.first
                self.state.isLoading = false
            }
            
            logger.debug("====================================")
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "VerificationFlowManager.initializeVerification",
                severity: .error
            )
            
            await MainActor.run {
                self.state.errorMessage = okidError.errorDescription ?? error.localizedDescription
                self.state.isLoading = false
            }
        }
    }
    
    // MARK: - Module Management
    
    func handleModuleComplete(module: String, nextStep: String?) {
        state.moduleProgress[module] = "completed"
        callbacks?.onModuleComplete(module: module, status: "completed")
        
        if let nextStep = nextStep {
            state.currentModule = nextStep
        } else {
            state.currentModule = "validation"
        }
    }
    
    func handleValidationComplete(result: OkIDVerificationResult) {
        state.hasCompletedOrCancelled = true
        
        Task {
            await notifyDesktopComplete(status: result.status)
        }
        
        callbacks?.onVerificationComplete(result: result)
    }
    
    func handleRetry() {
        state.hasCompletedOrCancelled = true
        callbacks?.onCancel()
    }
    
    func handleCancel() {
        state.hasCompletedOrCancelled = true
        callbacks?.onCancel()
    }
    
    func handleDeinitCancel() {
        if !state.hasCompletedOrCancelled {
            logger.debug("Deallocating without completion - calling onCancel")
            callbacks?.onCancel()
        }
    }
    
    // MARK: - Profile Helpers
    
    func shouldUseProfileForModule(_ module: String) -> Bool {
        guard state.profile != nil, let profileStatus = state.profileStatus else {
            return false
        }
        
        switch module {
        case "document":
            return profileStatus.document == .fresh
        case "liveness":
            return profileStatus.liveness == .fresh
        case "nfc":
            return profileStatus.nfc == .fresh
        default:
            return false
        }
    }
    
    // MARK: - Desktop Notifications
    
    private func notifyDesktopComplete(status: String) async {
        guard let desktopNotifier = desktopNotifier else { return }
        
        try? await desktopNotifier.notifyVerificationComplete(
            verificationId: verificationId,
            status: status
        )
    }
    
    // MARK: - Auto-Submit: Document
    
    func autoSubmitDocument() async {
        guard let profile = state.profile, let document = profile.document else {
            await MainActor.run {
                self.state.profile = self.state.profile?.copyWith(clearDocument: true)
                self.state.isAutoSubmitting = false
            }
            return
        }
        
        do {
            let apiClient = VerificationAPIClient(config: sdkConfig)
            apiClient.setVerificationId(verificationId)
            
            let tempDir = FileManager.default.temporaryDirectory
            let frontFile = tempDir.appendingPathComponent("profile_doc_front.jpg")
            try document.frontImage.write(to: frontFile)
            
            var blurScore = 150.0
            if let frontUIImage = document.frontImage.downsampledUIImage(maxPixelSize: 1024) {
                blurScore = BlurDetection.calculateBlurScore(image: frontUIImage)
            }
            
            var response = try await apiClient.uploadDocument(
                verificationId: verificationId,
                imageData: document.frontImage,
                side: "front",
                blurrinessScore: blurScore
            )
            
            if response.attemptResult.status == "rejected" {
                let reasonCode = response.attemptResult.reasonCode ?? "UNKNOWN"
                let message = response.attemptResult.message ?? "Image rejected"
                logger.debug("Image rejected: \(reasonCode) - \(message)")
                
                await MainActor.run {
                    self.state.errorMessage = "\(reasonCode): \(message)"
                }
                return
            }
            
            try? FileManager.default.removeItem(at: frontFile)
            
            if let backImage = document.backImage, response.nextStep == "document" {
                var backBlurScore = 150.0
                if let backUIImage = backImage.downsampledUIImage(maxPixelSize: 1024) {
                    backBlurScore = BlurDetection.calculateBlurScore(image: backUIImage)
                }
                
                response = try await apiClient.uploadDocument(
                    verificationId: verificationId,
                    imageData: backImage,
                    side: "back",
                    blurrinessScore: backBlurScore
                )
                
                if response.attemptResult.status == "rejected" {
                    let reasonCode = response.attemptResult.reasonCode ?? "UNKNOWN"
                    let message = response.attemptResult.message ?? "Image rejected"
                    logger.debug("Image rejected: \(reasonCode) - \(message)")
                    
                    await MainActor.run {
                        self.state.errorMessage = "\(reasonCode): \(message)"
                    }
                    return
                }
            }
            
            logger.debug("Document auto-submit complete, next: \(String(describing: response.nextStep))")
            
            let docConfig = parseDocumentConfig(state.modules["document"])
            let nfcEnabledInConfig = docConfig.readNfcFromPassport
            let rawMrz = response.attemptResult.metrics?.rawMrz
            let hasPassportMrz = rawMrz != nil && (rawMrz?.count ?? 0) >= 2
            let hasProfileNfc = shouldUseProfileForModule("nfc") && profile.nfc != nil
            
            if nfcEnabledInConfig && hasPassportMrz && hasProfileNfc {
                logger.debug("Passport detected with profile NFC data, auto-submitting NFC...")
                await MainActor.run {
                    self.state.autoSubmitMessage = "Submitting passport chip data..."
                }
                
                do {
                    try await submitProfileNfcData()
                    logger.debug("NFC auto-submit complete")
                } catch {
                    logger.error("NFC auto-submit failed: \(error) (continuing anyway)")
                }
            }
            
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.handleModuleComplete(module: "document", nextStep: response.nextStep)
            }
            
        } catch {
            logger.error("Document auto-submit failed: \(error)")
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.state.profile = profile.copyWith(clearDocument: true)
                self.state.profileStatus = OkIDProfileStatus(
                    document: .none,
                    liveness: self.state.profileStatus?.liveness ?? .none,
                    nfc: self.state.profileStatus?.nfc ?? .none
                )
            }
        }
    }
    
    // MARK: - Auto-Submit: Liveness
    
    func autoSubmitLiveness() async {
        guard let profile = state.profile, let liveness = profile.liveness else {
            await MainActor.run {
                self.state.profile = self.state.profile?.copyWith(clearLiveness: true)
                self.state.isAutoSubmitting = false
            }
            return
        }
        
        do {
            let apiClient = VerificationAPIClient(config: sdkConfig)
            apiClient.setVerificationId(verificationId)
            
            var biometricData: [String: Any]?
            if let estimatedAge = liveness.estimatedAge,
               let estimatedGender = liveness.estimatedGender {
                biometricData = [
                    "estimated_age": estimatedAge,
                    "estimated_gender": estimatedGender,
                    "gender_confidence": liveness.genderConfidence ?? 0.0
                ]
            } else if let selfieUIImage = liveness.selfieImage.downsampledUIImage(maxPixelSize: 640) {
                do {
                    let estimator = AgeGenderEstimator.shared
                    let faceDetector = FaceDetectionService.shared
                    let faces = try? await faceDetector.detectFaces(in: selfieUIImage)
                    let faceImage = faces?.first.flatMap { selfieUIImage.croppedFace(to: $0.boundingBox) } ?? selfieUIImage
                    let result = try await estimator.estimate(faceImage: faceImage)
                    biometricData = [
                        "estimated_age": result.age,
                        "estimated_gender": result.gender,
                        "gender_confidence": result.genderConfidence
                    ]
                } catch {
                    logger.error("Biometric estimation failed: \(error)")
                }
            }
            
            let response = try await apiClient.uploadSelfie(
                verificationId: verificationId,
                imageData: liveness.selfieImage,
                biometricData: biometricData
            )
            
            logger.debug("Liveness auto-submit complete, next: \(String(describing: response.nextStep))")
            
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.handleModuleComplete(module: "liveness", nextStep: response.nextStep)
            }
            
        } catch {
            logger.error("Liveness auto-submit failed: \(error)")
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.state.profile = profile.copyWith(clearLiveness: true)
                self.state.profileStatus = OkIDProfileStatus(
                    document: self.state.profileStatus?.document ?? .none,
                    liveness: .none,
                    nfc: self.state.profileStatus?.nfc ?? .none
                )
            }
        }
    }
    
    // MARK: - Auto-Submit: NFC
    
    func autoSubmitNfc() async {
        guard let profile = state.profile, let nfc = profile.nfc else {
            await MainActor.run {
                self.state.profile = self.state.profile?.copyWith(clearNfc: true)
                self.state.isAutoSubmitting = false
            }
            return
        }
        
        do {
            let apiClient = VerificationAPIClient(config: sdkConfig)
            apiClient.setVerificationId(verificationId)
            
            let personalInfo = convertToPersonalInfo(nfc.personalInfo)
            let passportData = OkIDPassportData(
                personalInfo: personalInfo,
                photo: nfc.photo,
                dataGroupsRead: nfc.dataGroupsRead,
                readAt: Date(timeIntervalSince1970: TimeInterval(nfc.capturedAt) / 1000)
            )
            
            let metadata: [String: Any] = [
                "source": "profile",
                "profile_captured_at": nfc.capturedAt,
                "data_groups_read": nfc.dataGroupsRead
            ]
            
            let response = try await apiClient.submitNfcData(
                verificationId: verificationId,
                passportData: passportData,
                metadata: metadata,
                photo: nfc.photo
            )
            
            logger.debug("NFC auto-submit complete, next: \(String(describing: response.nextStep))")
            
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.handleModuleComplete(module: "nfc", nextStep: response.nextStep)
            }
            
        } catch {
            logger.error("NFC auto-submit failed: \(error)")
            await MainActor.run {
                self.state.isAutoSubmitting = false
                self.state.autoSubmitMessage = nil
                self.state.profile = profile.copyWith(clearNfc: true)
                self.state.profileStatus = OkIDProfileStatus(
                    document: self.state.profileStatus?.document ?? .none,
                    liveness: self.state.profileStatus?.liveness ?? .none,
                    nfc: .none
                )
            }
        }
    }
    
    private func submitProfileNfcData() async throws {
        guard let profile = state.profile, let nfc = profile.nfc else {
            throw NSError(domain: "FlowManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No profile NFC data available"])
        }
        
        let apiClient = VerificationAPIClient(config: sdkConfig)
        apiClient.setVerificationId(verificationId)
        
        let personalInfo = convertToPersonalInfo(nfc.personalInfo)
        let passportData = OkIDPassportData(
            personalInfo: personalInfo,
            photo: nfc.photo,
            dataGroupsRead: nfc.dataGroupsRead,
            readAt: Date(timeIntervalSince1970: TimeInterval(nfc.capturedAt) / 1000)
        )
        
        let metadata: [String: Any] = [
            "source": "profile",
            "profile_captured_at": nfc.capturedAt,
            "data_groups_read": nfc.dataGroupsRead
        ]
        
        _ = try await apiClient.submitNfcData(
            verificationId: verificationId,
            passportData: passportData,
            metadata: metadata,
            photo: nfc.photo
        )
    }
    
    // MARK: - Helpers
    
    private func convertToPersonalInfo(_ profileInfo: OkIDProfilePassportInfo) -> OkIDPersonalInfo {
        let dateFormatter = ISO8601DateFormatter()
        
        return OkIDPersonalInfo(
            documentType: profileInfo.documentType,
            issuingState: profileInfo.issuingState,
            documentNumber: profileInfo.documentNumber,
            lastName: profileInfo.lastName,
            firstName: profileInfo.firstName,
            nationality: profileInfo.nationality,
            dateOfBirth: profileInfo.dateOfBirth != nil ? dateFormatter.date(from: profileInfo.dateOfBirth!) : nil,
            gender: profileInfo.gender,
            dateOfExpiry: profileInfo.dateOfExpiry != nil ? dateFormatter.date(from: profileInfo.dateOfExpiry!) : nil,
            optionalData1: profileInfo.optionalData1,
            optionalData2: profileInfo.optionalData2
        )
    }
    
    // MARK: - Config Parsing
    
    func parseTermsConfig(_ data: Any?) -> OkIDTermsModuleConfig {
        guard let dict = data as? [String: Any] else {
            logger.warning("parseTermsConfig: no data — using empty defaults")
            return OkIDTermsModuleConfig(
                required: true,
                version: "1.0",
                title: "Terms and Conditions",
                content: "",
                acceptanceRequired: true
            )
        }

        // Fast path: all required fields present — strict Codable decode.
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let config = try? JSONDecoder().decode(OkIDTermsModuleConfig.self, from: jsonData) {
            return config
        }

        // Lenient path: backend omitted one or more required fields.
        // Extract whatever was sent and fill gaps with neutral defaults so the
        // real content (if provided) is never replaced by placeholder text.
        logger.warning("parseTermsConfig: strict decode failed — falling back to lenient field extraction")
        return OkIDTermsModuleConfig(
            required:           dict["required"]            as? Bool   ?? true,
            version:            dict["version"]             as? String ?? "1.0",
            title:              dict["title"]               as? String ?? "Terms and Conditions",
            content:            dict["content"]             as? String ?? "",
            displaySummary:     dict["display_summary"]     as? String,
            acceptanceRequired: dict["acceptance_required"] as? Bool   ?? true
        )
    }
    
    func parseDocumentConfig(_ data: Any?) -> OkIDDocumentModuleConfig {
        logger.debug("========== PARSING DOCUMENT CONFIG ==========")
        
        if let dict = data as? [String: Any] {
            logger.debug("Parsing from JSON...")
            logger.debug("read_nfc_from_passport in data: \(String(describing: dict["read_nfc_from_passport"]))")
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let config = try? JSONDecoder().decode(OkIDDocumentModuleConfig.self, from: jsonData) {
                logger.debug("readNfcFromPassport: \(config.readNfcFromPassport)")
                logger.debug("=============================================")
                return config
            }
        }
        
        logger.debug("Using DEFAULT config")
        logger.debug("=============================================")
        
        return OkIDDocumentModuleConfig(
            required: true,
            acceptedDocuments: ["passport", "id_card", "drivers_license"],
            qualityThreshold: 6.0,
            allowFileUpload: true,
            readNfcFromPassport: false
        )
    }
    
    func parseLivenessConfig(_ data: Any?) -> OkIDLivenessModuleConfig {
        if let dict = data as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let config = try? JSONDecoder().decode(OkIDLivenessModuleConfig.self, from: jsonData) {
            return config
        }
        
        return OkIDLivenessModuleConfig(
            required: true,
            mode: "passive",
            threshold: 0.85,
            maxAttempts: 3
        )
    }
    
    func parseFormDataConfig(_ data: Any?) -> OkIDFormDataModuleConfig {
        if let dict = data as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let config = try? JSONDecoder().decode(OkIDFormDataModuleConfig.self, from: jsonData) {
            return config
        }
        
        return OkIDFormDataModuleConfig(
            required: true,
            fields: [
                OkIDFormField(name: "full_name", type: "text", label: "Full Name", required: true),
                OkIDFormField(name: "email", type: "email", label: "Email", required: true)
            ],
            allowPartialSave: false
        )
    }
}
