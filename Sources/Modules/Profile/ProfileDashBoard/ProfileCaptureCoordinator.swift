import UIKit
import ObjectiveC

/// Coordinator that wraps existing capture screens for profile mode
///
/// In profile mode, captured data is returned to caller instead of
/// being submitted to backend. The caller (ProfileDashboardViewController)
/// handles storage.
public class ProfileCaptureCoordinator {
    
    // Associated object key for retaining coordinators
    private static var coordinatorKey: UInt8 = 0
    
    // MARK: - Factory Methods
    
    /// Create coordinator for document capture
    public static func documentCapture(
        config: OkIDSDKConfig,
        completion: @escaping (OkIDProfileDocumentData?) -> Void
    ) -> UIViewController {
        let coordinator = DocumentCaptureCoordinator(config: config, completion: completion)
        let viewController = coordinator.viewController
        
        // Retain coordinator for the lifetime of the view controller
        objc_setAssociatedObject(viewController, &coordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return viewController
    }
    
    /// Create coordinator for liveness/selfie capture
    public static func livenessCapture(
        config: OkIDSDKConfig,
        completion: @escaping (OkIDProfileLivenessData?) -> Void
    ) -> UIViewController {
        let coordinator = LivenessCaptureCoordinator(config: config, completion: completion)
        let viewController = coordinator.viewController
        
        // Retain coordinator for the lifetime of the view controller
        objc_setAssociatedObject(viewController, &coordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return viewController
    }
    
    /// Create coordinator for NFC capture
    public static func nfcCapture(
        config: OkIDSDKConfig,
        completion: @escaping (OkIDProfileNfcData?) -> Void
    ) -> UIViewController {
        let coordinator = NfcCaptureCoordinator(config: config, completion: completion)
        let viewController = coordinator.viewController
        
        // Retain coordinator for the lifetime of the view controller
        objc_setAssociatedObject(viewController, &coordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return viewController
    }
}

// MARK: - Document Capture State

private enum DocumentCaptureState {
    case front
    case back
    case complete
}

// MARK: - Document Capture Coordinator

private class DocumentCaptureCoordinator: NSObject {
    private let config: OkIDSDKConfig
    private let completion: (OkIDProfileDocumentData?) -> Void
    
    // State tracking
    private var documentState: DocumentCaptureState = .front
    private var frontImageData: Data?
    private var backImageData: Data?
    
    private var navigationController: UINavigationController?
    
    lazy var viewController: UIViewController = {
        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen
        self.navigationController = nav
        
        // Start with front side capture
        buildDocumentCapture()
        
        return nav
    }()
    
    init(config: OkIDSDKConfig, completion: @escaping (OkIDProfileDocumentData?) -> Void) {
        self.config = config
        self.completion = completion
    }
    
    private func buildDocumentCapture() {
        switch documentState {
        case .front:
            let frontVC = createDocumentCameraViewController(side: "front")
            navigationController?.setViewControllers([frontVC], animated: false)
        case .back:
            // Replace the stack entirely so the front camera VC is deallocated.
            // On memory-constrained devices (iPhone 6s) keeping the old camera
            // VC alive prevents the new session from acquiring the camera.
            let backPromptVC = createBackSidePromptViewController()
            navigationController?.setViewControllers([backPromptVC], animated: true)
        case .complete:
            break
        }
    }
    
    private func createDocumentCameraViewController(side: String) -> UIViewController {
        let cameraVC = DocumentCameraViewController(
            side: side,
            qualityThreshold: 6.0,
            primaryColor: config.theme.colors.primary,
            onImageCaptured: { [weak self] imageData, blurScore in
                self?.handleImageCaptured(imageData, for: side)
            },
            onCancel: { [weak self] in
                self?.completion(nil)
            }
        )
        return cameraVC
    }
    
    private func handleImageCaptured(_ imageData: Data, for side: String) {
        // This callback arrives from AVFoundation's capture queue (background thread).
        // All UIKit / navigation work must happen on the main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if side == "front" {
                self.frontImageData = imageData
                self.documentState = .back
                self.buildDocumentCapture()
            } else {
                self.backImageData = imageData
                self.documentState = .complete
                self.completeDocumentCapture()
            }
        }
    }
    
    private func createBackSidePromptViewController() -> UIViewController {
        let promptVC = BackSidePromptViewController(
            primaryColor: config.theme.colors.primary,
            onCaptureBack: { [weak self] in
                self?.captureBackSide()
            },
            onSkipBack: { [weak self] in
                self?.completeDocumentCapture()
            },
            onClose: { [weak self] in
                self?.completion(nil)
            }
        )
        return promptVC
    }
    
    private func captureBackSide() {
        let backVC = DocumentCameraViewController(
            side: "back",
            qualityThreshold: 6.0,
            primaryColor: config.theme.colors.primary,
            onImageCaptured: { [weak self] imageData, blurScore in
                self?.backImageData = imageData
                self?.navigationController?.popViewController(animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.completeDocumentCapture()
                }
            },
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        )
        navigationController?.pushViewController(backVC, animated: true)
    }
    
    private func completeDocumentCapture() {
        guard let frontImageData = frontImageData else {
        completion(nil)
            return
        }
        
        let result = OkIDProfileDocumentData(
            frontImage: frontImageData,
            backImage: backImageData,
            capturedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        completion(result)
    }
}

// MARK: - Liveness Capture Coordinator

private class LivenessCaptureCoordinator: NSObject {
    private let config: OkIDSDKConfig
    private let completion: (OkIDProfileLivenessData?) -> Void
    
    lazy var viewController: UIViewController = {
        let livenessVC = LivenessCameraScreen(
            onImageCaptured: { [weak self] imageData, biometricData in
                self?.handleImageCaptured(imageData, biometricData: biometricData)
            },
            onCancel: { [weak self] in
                self?.completion(nil)
            }
        )
        livenessVC.modalPresentationStyle = .fullScreen
        return livenessVC
    }()
    
    init(config: OkIDSDKConfig, completion: @escaping (OkIDProfileLivenessData?) -> Void) {
        self.config = config
        self.completion = completion
    }
    
    private func handleImageCaptured(_ imageData: Data, biometricData: [String: Any]?) {
        let result = OkIDProfileLivenessData(
            selfieImage: imageData,
            capturedAt: Int64(Date().timeIntervalSince1970 * 1000),
            estimatedAge: biometricData?["avg_age"] as? Double,
            estimatedGender: biometricData?["gender"] as? String,
            genderConfidence: biometricData?["gender_confidence"] as? Double
        )
        
        completion(result)
    }
}

// MARK: - NFC Capture State

private enum NfcCaptureState {
    case input
    case reading
}

// MARK: - NFC Capture Coordinator

private class NfcCaptureCoordinator: NSObject {
    private let config: OkIDSDKConfig
    private let completion: (OkIDProfileNfcData?) -> Void
    
    // State tracking
    private var nfcState: NfcCaptureState = .input
    private var nfcCredentials: OkIDPassportCredentials?
    
    private var navigationController: UINavigationController?
    
    lazy var viewController: UIViewController = {
        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen
        self.navigationController = nav
        
        // Start with input screen
        buildNfcCapture()
        
        return nav
    }()
    
    init(config: OkIDSDKConfig, completion: @escaping (OkIDProfileNfcData?) -> Void) {
        self.config = config
        self.completion = completion
    }
    
    private func buildNfcCapture() {
        switch nfcState {
        case .input:
            let inputVC = NFCInputViewController(
                onStart: { [weak self] credentials in
                    self?.handleCredentialsEntered(credentials)
                },
                onCancel: { [weak self] in
                    self?.completion(nil)
                },
                primaryColor: config.theme.colors.primary,
                initialCredentials: nil
            )
            navigationController?.setViewControllers([inputVC], animated: false)
            
        case .reading:
            guard let credentials = nfcCredentials else {
                nfcState = .input
                buildNfcCapture()
                return
            }
            
            let readingVC = NFCReadingViewController(
                credentials: credentials,
                primaryColor: config.theme.colors.primary,
                onSuccess: { [weak self] passportData in
                    self?.completeNfcCapture(passportData)
                },
                onError: { [weak self] errorMessage in
                    self?.handleNfcError(errorMessage)
                },
                onCancel: { [weak self] in
                    self?.nfcState = .input
                    self?.buildNfcCapture()
                }
            )
            navigationController?.pushViewController(readingVC, animated: true)
        }
    }
    
    private func handleCredentialsEntered(_ credentials: OkIDPassportCredentials) {
        nfcCredentials = credentials
        nfcState = .reading
        buildNfcCapture()
    }
    
    private func handleNfcError(_ errorMessage: String) {
        // Go back to input on error
        navigationController?.popViewController(animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.nfcState = .input
            
            // Show error alert
            if let topVC = self.navigationController?.topViewController {
                OkIDAlert.showError(
                    title: "NFC Read Failed",
                    message: errorMessage,
                    from: topVC
                )
            }
        }
    }
    
    private func completeNfcCapture(_ passportData: OkIDPassportData) {
        // Convert PassportData to ProfileNfcData
        let info = passportData.personalInfo
        
        // Date formatter for converting Date to String (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let profileInfo: OkIDProfilePassportInfo? = info != nil ? OkIDProfilePassportInfo(
            documentType: info!.documentType,
            issuingState: info!.issuingState,
            documentNumber: info!.documentNumber,
            lastName: info!.lastName,
            firstName: info!.firstName,
            nationality: info!.nationality,
            dateOfBirth: info!.dateOfBirth != nil ? dateFormatter.string(from: info!.dateOfBirth!) : nil,
            gender: info!.gender,
            dateOfExpiry: info!.dateOfExpiry != nil ? dateFormatter.string(from: info!.dateOfExpiry!) : nil,
            optionalData1: info!.optionalData1,
            optionalData2: info!.optionalData2
        ) : nil
        
        let result = OkIDProfileNfcData(
            personalInfo: profileInfo!,
            photo: passportData.photo,
            dataGroupsRead: passportData.dataGroupsRead,
            capturedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        completion(result)
    }
}

