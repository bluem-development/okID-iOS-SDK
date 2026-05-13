import UIKit
import OkIDVerificationSDK

/// Example usage of OkID Verification SDK
/// 
/// This file demonstrates all major features and best practices for integrating
/// the OkID Verification SDK into your iOS application.
///
/// ## Contents:
/// - **Basic Usage**: Simple verification flow
/// - **Get Result**: Verification with result handling
/// - **QR Code Flow**: Scan and verify from QR code
/// - **Custom Theme**: Branding and UI customization
/// - **Profile Management**: Check, manage, and delete profiles
/// - **Error Handling**: Comprehensive error handling with OkIDError
/// - **Callbacks**: Custom verification callbacks
/// - **Custom Flow**: Module order and configuration
/// - **Desktop Integration**: Desktop notification support
/// - **Age/Gender Estimation**: Biometric analysis
/// - **Document Quality**: Real-time quality validation
/// - **Advanced Error Handling**: Retry logic, monitoring, and graceful degradation
///
/// ## Version: 1.0.0
/// ## Last Updated: 2026-01-27
class ExampleViewController: UIViewController {
    
    // MARK: - SDK Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable debug logging (disable in production)
        OkIDVerificationSDK.setLoggingEnabled(true)
        
        // Setup error listener
        setupErrorListener()
    }
    
    // MARK: - Basic Usage
    
    func startBasicVerification() {
        Task {
            // Configure SDK
            let config = OkIDSDKConfig(
                baseUrl: "https://api.okid.com"
            )
            
            // Start verification
            await OkIDVerificationSDK.shared.startVerification(
                verificationId: "ver_1234567890",
                config: config,
                from: self
            )
        }
    }
    
    // MARK: - Get Result
    
    func startVerificationWithResult() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            let result = await OkIDVerificationSDK.shared.startVerificationForResult(
                verificationId: "ver_1234567890",
                config: config,
                from: self
            )
            
            if let result = result {
                handleVerificationResult(result)
            }
        }
    }
    
    func handleVerificationResult(_ result: OkIDVerificationResult) {
        if result.isSuccess {
            print("✓ Verification successful")
            // Navigate to success screen
        } else if result.isManualReview {
            print("⏳ Under manual review")
            // Show pending screen
        } else if result.isRejected {
            print("✗ Verification rejected")
            // Show rejection reason
        }
    }
    
    // MARK: - QR Code Flow
    
    func startFromQRCode() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            // Allow only specific origins
            let allowedOrigins = ["https://verify.okid.com"]
            
            let result = await OkIDVerificationSDK.shared.startFromQRCode(
                from: self,
                config: config,
                allowedOrigins: allowedOrigins
            )
            
            if let result = result {
                print("Verification completed via QR: \\(result.status)")
            }
        }
    }
    
    // MARK: - Custom Theme
    
    func startWithCustomTheme() {
        Task {
            // Create custom color palette
            let customColors = OkIDColorPalette(
                primary: UIColor(rgb: 0x007AFF),
                secondary: UIColor(rgb: 0x8E8E93),
                accent: UIColor(rgb: 0x34C759),
                warning: UIColor(rgb: 0xFF9500),
                error: UIColor(rgb: 0xFF3B30),
                background: .white,
                surface: UIColor(rgb: 0xF2F2F7),
                text: .black,
                textSecondary: UIColor(rgb: 0x8E8E93),
                border: UIColor(rgb: 0xC6C6C8)
            )
            
            // Create branding
            let branding = OkIDBrandingConfig(
                organizationName: "Acme Corp",
                logoImage: UIImage(named: "acme-logo"),
                primaryColor: UIColor(rgb: 0x007AFF),
                secondaryColor: UIColor(rgb: 0x8E8E93)
            )
            
            // Create theme
            let theme = OkIDThemeConfig(
                colors: customColors,
                typography: .defaultConfig,
                spacing: .defaultConfig,
                branding: branding,
                borderRadius: .defaultConfig
            )
            
            let config = OkIDSDKConfig(
                baseUrl: "https://api.okid.com",
                theme: theme
            )
            
            await OkIDVerificationSDK.shared.startVerification(
                verificationId: "ver_1234567890",
                config: config,
                from: self
            )
        }
    }
    
    // MARK: - Profile Management
    
    func checkProfileStatus() {
        Task {
            // Check if profile exists
            let hasProfile = await OkIDVerificationSDK.shared.hasProfile()
            print("Has profile: \\(hasProfile)")
            
            // Get detailed status
            let status = await OkIDVerificationSDK.shared.getProfileStatus()
            print("Document status: \\(status.document)")
            print("Liveness status: \\(status.liveness)")
            print("NFC status: \\(status.nfc)")
            print("Fresh data count: \\(status.freshCount)")
        }
    }
    
    func openProfileDashboard() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            let result = await OkIDVerificationSDK.shared.manageProfile(
                from: self,
                config: config
            )
            
            if let result = result, result.modified {
                print("Profile was modified")
            }
        }
    }
    
    func deleteProfile() {
        Task {
            await OkIDVerificationSDK.shared.deleteProfile()
            print("Profile deleted")
        }
    }
    
    // MARK: - Error Handling
    
    /// Setup global error listener for monitoring
    func setupErrorListener() {
        OkIDErrorHandler.shared.addErrorListener { [weak self] error in
            // Log to analytics service
            Analytics.track("sdk_error", properties: [
                "category": error.category.rawValue,
                "description": error.errorDescription ?? "unknown",
                "recoverable": error.isRecoverable,
                "requires_user_action": error.requiresUserAction
            ])
            
            // Handle critical errors
            if !error.isRecoverable {
                self?.handleCriticalError(error)
            }
        }
    }
    
    /// Handle verification with comprehensive error handling
    func startVerificationWithErrorHandling() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            do {
                let result = await OkIDVerificationSDK.shared.startVerificationForResult(
                    verificationId: "ver_1234567890",
                    config: config,
                    from: self
                )
                
                if let result = result {
                    handleVerificationResult(result)
                }
            } catch let error as OkIDError {
                // Handle specific error types
                switch error {
                case .networkUnavailable:
                    showRetryAlert("No internet connection. Please check your network.")
                    
                case .verificationExpired:
                    showAlert("This verification has expired. Please request a new one.")
                    
                case .cameraPermissionDenied:
                    showSettingsAlert("Camera access is required for verification.")
                    
                case .nfcNotSupported:
                    showAlert("Your device doesn't support NFC reading.")
                    
                case .rateLimitExceeded(let retryAfter):
                    let message = retryAfter.map {
                        "Too many attempts. Please try again in \(Int($0)) seconds."
                    } ?? "Too many attempts. Please try again later."
                    showAlert(message)
                    
                case .documentBlurry(let score, let threshold):
                    showAlert("Document image is too blurry. Score: \(score)/\(threshold)")
                    
                case .serverError(let statusCode, let message):
                    showAlert("Server error (\(statusCode)): \(message ?? "Unknown")")
                    
                default:
                    // Generic error handling
                    let errorMessage = error.errorDescription ?? "An unexpected error occurred"
                    let recoverySuggestion = error.recoverySuggestion
                    
                    if error.isRecoverable && error.requiresUserAction {
                        showRetryAlert(errorMessage, suggestion: recoverySuggestion)
                    } else {
                        showAlert(errorMessage)
                    }
                }
                
                // Log error with context
                OkIDErrorHandler.shared.handle(
                    error,
                    context: "ExampleViewController.startVerificationWithErrorHandling",
                    severity: .error
                )
            } catch {
                // Handle unexpected errors
                let okidError = OkIDErrorHandler.shared.normalize(error)
                showAlert(okidError.errorDescription ?? "An unexpected error occurred")
            }
        }
    }
    
    /// Present error with retry option
    func startVerificationWithRetry() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            let result = await OkIDVerificationSDK.shared.startVerificationForResult(
                verificationId: "ver_1234567890",
                config: config,
                from: self
            )
            
            // Using Result extension for error handling
            await result?.handleError { [weak self] error in
                guard let self = self else { return }
                
                // Present error with UI
                await OkIDErrorHandler.shared.presentError(
                    error,
                    in: self,
                    allowRetry: error.isRecoverable
                ) { shouldRetry in
                    if shouldRetry {
                        // Retry verification
                        self.startVerificationWithRetry()
                    }
                }
            }
        }
    }
    
    // MARK: - Callbacks
    
    func startWithCallbacks() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            let callbacks = VerificationCallbacksImpl()
            
            await OkIDVerificationSDK.shared.startVerification(
                verificationId: "ver_1234567890",
                config: config,
                from: self,
                callbacks: callbacks
            )
        }
    }
    
    // MARK: - Custom Flow
    
    func startWithCustomFlow() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            // Custom module order
            let flow = ["terms", "liveness", "document", "form_data", "validation"]
            
            // Custom module configurations
            let modules: [String: Any] = [
                "document": [
                    "quality_threshold": 8.0,
                    "read_nfc_from_passport": true,
                    "accepted_documents": ["passport", "id_card"]
                ],
                "liveness": [
                    "mode": "passive",
                    "threshold": 0.9,
                    "max_attempts": 3
                ]
            ]
            
            await OkIDVerificationSDK.shared.startVerification(
                verificationId: "ver_1234567890",
                config: config,
                from: self,
                flow: flow,
                modules: modules
            )
        }
    }
    
    // MARK: - Desktop Integration
    
    func startWithDesktopNotification() {
        Task {
            let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
            
            let result = await OkIDVerificationSDK.shared.startVerificationForResult(
                verificationId: "ver_1234567890",
                config: config,
                from: self,
                desktopSessionId: "session_abc123",
                portalBaseUrl: "https://verify.okid.com"
            )
            
            // Desktop will be notified automatically when complete
        }
    }
}

// MARK: - Callbacks Implementation

class VerificationCallbacksImpl: OkIDVerificationCallbacks {
    
    func onModuleComplete(module: String, status: String) {
        print("📋 Module \\(module) completed: \\(status)")
        
        // Track analytics
        Analytics.track("module_complete", properties: [
            "module": module,
            "status": status
        ])
    }
    
    func onVerificationComplete(result: OkIDVerificationResult) {
        print("✅ Verification complete: \\(result.status)")
        
        // Handle based on status
        switch result.status {
        case "verified":
            showSuccessScreen()
        case "needs_manual_review":
            showReviewPendingScreen()
        case "rejected":
            showRejectionScreen(reason: result.error)
        default:
            showGenericResultScreen(status: result.status)
        }
    }
    
    func onError(error: String) {
        print("❌ Error: \\(error)")
        
        // Parse error and provide better user experience
        if error.contains("network") || error.contains("connection") {
            showErrorAlert(message: "Network connection lost. Please check your internet.")
        } else if error.contains("timeout") {
            showErrorAlert(message: "Request timed out. Please try again.")
        } else {
            showErrorAlert(message: error)
        }
        
        // Log to analytics
        Analytics.track("verification_error", properties: ["error": error])
    }
    
    func onCancel() {
        print("⚠️ User cancelled verification")
        // Return to previous screen
    }
    
    // Helper methods
    
    private func showSuccessScreen() {
        // Implementation
    }
    
    private func showReviewPendingScreen() {
        // Implementation
    }
    
    private func showRejectionScreen(reason: String?) {
        // Implementation
    }
    
    private func showGenericResultScreen(status: String) {
        // Implementation
    }
    
    private func showErrorAlert(message: String) {
        // Implementation
    }
}

    // MARK: - Age/Gender Estimation
    
    func estimateAgeGender() {
        Task {
            let estimator = AgeGenderEstimator.shared
            
            do {
                // Initialize estimator
                try await estimator.initialize()
                
                // Get face image (from camera or gallery)
                guard let faceImage = getFaceImage() else { return }
                
                // Estimate
                let result = try await estimator.estimate(faceImage: faceImage)
                
                print("Age: \(String(format: "%.1f", result.age)) years")
                print("Gender: \(result.gender)")
                print("Confidence: \(String(format: "%.1f%%", result.genderConfidence * 100))")
                
                // Use in verification
                let biometricData: [String: Any] = [
                    "estimated_age": result.age,
                    "estimated_gender": result.gender,
                    "gender_confidence": result.genderConfidence
                ]
                
                // Upload with selfie
                // await uploadSelfie(image: faceImage, metadata: biometricData)
                
            } catch {
                print("Estimation failed: \(error)")
            }
        }
    }
    
    // MARK: - Document Quality Validation
    
    func validateDocumentQuality() {
        Task {
            let processor = DocumentProcessor.shared
            await processor.initialize()
            
            guard let documentImage = getDocumentImage() else { return }
            
            do {
                // Process document
                let quality = try await processor.processDocument(image: documentImage)
                
                print("Quality Score: \(quality.blurScore)")
                print("Status: \(quality.qualityDescription)")
                
                // Check individual metrics
                if quality.isBlurry {
                    showAlert("Image is too blurry. Use better lighting.")
                    return
                }
                
                if quality.hasGlare {
                    showAlert("Glare detected. Adjust lighting.")
                    return
                }
                
                if !quality.isCentered {
                    showAlert("Center the document in frame.")
                    return
                }
                
                if !quality.hasGoodSize {
                    showAlert("Move closer to the document.")
                    return
                }
                
                if quality.isGoodQuality {
                    print("✓ Document quality is excellent!")
                    // Proceed with upload
                    await uploadDocument(image: documentImage, quality: quality)
                }
                
            } catch {
                print("Validation failed: \(error)")
            }
        }
    }
    
    // MARK: - Document Boundary Detection
    
    func detectDocumentBoundaries() {
        Task {
            let processor = DocumentProcessor.shared
            
            guard let image = getDocumentImage() else { return }
            
            do {
                // Detect boundaries
                let boundaries = try await processor.detectDocumentBoundaries(image: image)
                
                if let boundaries = boundaries {
                    print("Document detected!")
                    print("Top-left: (\(boundaries.topLeft.x), \(boundaries.topLeft.y))")
                    print("Top-right: (\(boundaries.topRight.x), \(boundaries.topRight.y))")
                    print("Bottom-right: (\(boundaries.bottomRight.x), \(boundaries.bottomRight.y))")
                    print("Bottom-left: (\(boundaries.bottomLeft.x), \(boundaries.bottomLeft.y))")
                    print("Center: (\(boundaries.center.x), \(boundaries.center.y))")
                    print("Area: \(boundaries.area) px²")
                    print("Confidence: \(String(format: "%.2f", boundaries.confidence))")
                    
                    // Draw boundaries on image
                    let imageWithBoundaries = drawBoundaries(on: image, boundaries: boundaries)
                    // Display imageWithBoundaries
                }
                
            } catch {
                print("Detection failed: \(error)")
            }
        }
    }
    
    // MARK: - Combined Quality + Boundaries
    
    func analyzeDocument() {
        Task {
            let processor = DocumentProcessor.shared
            await processor.initialize()
            
            guard let image = getDocumentImage() else { return }
            
            do {
                // Get quality
                let quality = try await processor.processDocument(image: image)
                
                // Get boundaries
                let boundaries = try await processor.detectDocumentBoundaries(image: image)
                
                print("=== Document Analysis ===")
                print("Quality: \(quality.qualityDescription)")
                print("Blur Score: \(quality.blurScore)")
                print("Confidence: \(quality.confidence)")
                
                if let bounds = boundaries {
                    print("Boundaries detected: \(bounds.confidence)")
                    print("Area: \(bounds.area) px²")
                    print("Centered: \(processor.isDocumentCentered(boundaries: bounds, imageSize: image.size))")
                    print("Good size: \(processor.hasGoodSize(boundaries: bounds, imageSize: image.size))")
                }
                
                // Glare check
                let hasGlare = try await processor.hasGlare(image: image)
                print("Has glare: \(hasGlare)")
                
            } catch {
                print("Analysis failed: \(error)")
            }
        }
    }
    
    // MARK: - Real-time Quality Feedback
    
    func provideLiveQualityFeedback(cameraFrame: UIImage) {
        Task {
            let processor = DocumentProcessor.shared
            
            do {
                let quality = try await processor.processDocument(image: cameraFrame)
                
                // Update UI with feedback
                await MainActor.run {
                    if quality.isBlurry {
                        showFeedback("Hold steady - image is blurry")
                    } else if quality.hasGlare {
                        showFeedback("Reduce glare")
                    } else if !quality.isCentered {
                        showFeedback("Center document")
                    } else if !quality.hasGoodSize {
                        showFeedback("Move closer")
                    } else {
                        showFeedback("✓ Good quality - tap to capture")
                    }
                }
            } catch {
                print("Feedback error: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFaceImage() -> UIImage? {
        // Get from camera or gallery
        return UIImage(named: "sample-face")
    }
    
    private func getDocumentImage() -> UIImage? {
        // Get from camera or gallery
        return UIImage(named: "sample-document")
    }
    
    private func uploadDocument(image: UIImage, quality: DocumentQualityResult) async {
        print("Uploading document with quality score: \(quality.blurScore)")
    }
    
    private func drawBoundaries(on image: UIImage, boundaries: DocumentBoundaries) -> UIImage {
        // Draw boundary lines on image
        return image
    }
    
    private func showAlert(_ message: String) {
        print("Alert: \(message)")
    }
    
    private func showFeedback(_ message: String) {
        print("Feedback: \(message)")
    }
    
    private func handleCriticalError(_ error: OkIDError) {
        print("Critical error: \(error)")
        // Navigate to error screen or exit flow
    }
    
    private func showRetryAlert(_ message: String, suggestion: String? = nil) {
        let fullMessage = suggestion.map { "\(message)\n\n\($0)" } ?? message
        
        let alert = UIAlertController(
            title: "Error",
            message: fullMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.startVerificationWithRetry()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSettingsAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Permission Required",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - Advanced Error Handling Examples

extension ExampleViewController {
    
    /// Monitor all SDK errors for debugging
    func setupErrorMonitoring() {
        OkIDErrorHandler.shared.addErrorListener { error in
            // Log to remote logging service (e.g., Sentry, Firebase Crashlytics)
            print("📊 Error logged: \(error.category.rawValue)")
            print("   Description: \(error.errorDescription ?? "N/A")")
            print("   Recoverable: \(error.isRecoverable)")
            print("   User action required: \(error.requiresUserAction)")
            
            // Send to analytics
            Analytics.track("sdk_error_occurred", properties: [
                "error_category": error.category.rawValue,
                "error_code": "\(error)",
                "is_recoverable": error.isRecoverable,
                "requires_user_action": error.requiresUserAction
            ])
        }
    }
    
    /// Handle errors by category
    func handleErrorByCategory(_ error: OkIDError) {
        switch error.category {
        case .network:
            showNetworkErrorUI()
            
        case .authentication:
            handleAuthenticationError()
            
        case .validation:
            showValidationErrorMessage(error.errorDescription ?? "Validation failed")
            
        case .document:
            showDocumentCaptureGuidance()
            
        case .liveness:
            showLivenessGuidance()
            
        case .nfc:
            handleNFCError(error)
            
        case .camera:
            requestCameraPermission()
            
        case .storage:
            showStorageFullWarning()
            
        case .configuration:
            // Log configuration error - this shouldn't happen in production
            print("⚠️ Configuration error: \(error)")
            
        case .generic:
            showGenericError(error.errorDescription ?? "Something went wrong")
        }
    }
    
    /// Example: Graceful degradation for NFC errors
    func handleNFCError(_ error: OkIDError) {
        if case .nfcNotSupported = error {
            // Offer alternative verification without NFC
            showAlert("NFC is not supported on this device. You can complete verification without it.")
        } else if case .nfcNotEnabled = error {
            showAlert("Please enable NFC in Settings to read your passport.")
        } else {
            showAlert(error.errorDescription ?? "NFC reading failed")
        }
    }
    
    /// Example: Retry logic with exponential backoff
    func startVerificationWithRetryLogic(maxRetries: Int = 3) {
        Task {
            var attempts = 0
            
            while attempts < maxRetries {
                do {
                    let config = OkIDSDKConfig(baseUrl: "https://api.okid.com")
                    
                    let result = await OkIDVerificationSDK.shared.startVerificationForResult(
                        verificationId: "ver_1234567890",
                        config: config,
                        from: self
                    )
                    
                    if let result = result {
                        handleVerificationResult(result)
                        return // Success
                    }
                } catch let error as OkIDError {
                    attempts += 1
                    
                    // Only retry for recoverable network errors
                    if error.isRecoverable && error.category == .network && attempts < maxRetries {
                        let delay = pow(2.0, Double(attempts)) // Exponential backoff: 2s, 4s, 8s
                        print("Retry attempt \(attempts)/\(maxRetries) after \(delay)s")
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    } else {
                        // Non-recoverable error or max retries reached
                        OkIDErrorHandler.shared.handle(error, context: "Max retries reached")
                        showAlert(error.errorDescription ?? "Verification failed")
                        return
                    }
                } catch {
                    print("Unexpected error: \(error)")
                    return
                }
            }
        }
    }
    
    // Helper methods for error handling
    
    private func showNetworkErrorUI() {
        showAlert("Network connection issue. Please check your internet and try again.")
    }
    
    private func handleAuthenticationError() {
        showAlert("Authentication failed. Please contact support.")
    }
    
    private func showValidationErrorMessage(_ message: String) {
        showAlert(message)
    }
    
    private func showDocumentCaptureGuidance() {
        showAlert("Please ensure good lighting and hold your document steady.")
    }
    
    private func showLivenessGuidance() {
        showAlert("Position your face in the frame and ensure good lighting.")
    }
    
    private func requestCameraPermission() {
        showSettingsAlert("Camera permission is required for verification.")
    }
    
    private func showStorageFullWarning() {
        showAlert("Device storage is full. Please free up space and try again.")
    }
    
    private func showGenericError(_ message: String) {
        showAlert(message)
    }
}

// MARK: - Mock Analytics

class Analytics {
    static func track(_ event: String, properties: [String: Any]) {
        print("📊 Analytics: \(event) - \(properties)")
    }
}

