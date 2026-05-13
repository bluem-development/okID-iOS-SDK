import UIKit
import AVFoundation
import CoreNFC

private let logger = Logger.document

/// Document capture module with full NFC integration
/// REFACTORED to follow proper MVC pattern
/// - Uses DocumentState for state management
/// - Uses DocumentManager for business logic
/// - Uses separate View classes for UI
/// - Controller coordinates between Model, View, and business logic
@MainActor
public class DocumentViewController: UIViewController {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDDocumentModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let profileNfcData: OkIDProfileNfcData?
    private let onComplete: (String?) -> Void
    
    // MARK: - MVC Components
    
    private let documentState: DocumentState
    private let documentManager: DocumentManager
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var currentView: UIView?
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        config: OkIDDocumentModuleConfig,
        sdkConfig: OkIDSDKConfig,
        profileNfcData: OkIDProfileNfcData? = nil,
        onComplete: @escaping (String?) -> Void
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.profileNfcData = profileNfcData
        self.onComplete = onComplete
        
        // Initialize MVC components
        self.documentState = DocumentState()
        self.documentManager = DocumentManager(
            verificationId: verificationId,
            config: config,
            sdkConfig: sdkConfig,
            profileNfcData: profileNfcData
        )
        
        super.init(nibName: nil, bundle: nil)
        
        setupStateObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Document"
        view.backgroundColor = .white
        navigationItem.hidesBackButton = true
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(backButtonTapped)
        )
        
        setupUI()
        
        logger.debug("Started with readNfcFromPassport: \(config.readNfcFromPassport)")
        
        // Check NFC availability
        if config.readNfcFromPassport {
            checkNFCAvailability()
        }
        
        // Auto-submit profile NFC if available
        if let _ = profileNfcData {
            autoSubmitProfileNFC()
        } else {
            // Show initial view if not auto-submitting
            updateUI(for: .initial)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStateObservers() {
        // Observe state changes
        documentState.onStateChanged = { [weak self] newState in
            self?.handleStateChange(newState)
        }
        
        documentState.onSideChanged = { [weak self] newSide in
            self?.handleSideChange(newSide)
        }
        
        documentState.onError = { [weak self] error in
            self?.handleError(error)
        }
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: DocumentModuleState) {
        logger.debug("State changed to: \(state)")
        updateUI(for: state)
    }
    
    private func handleSideChange(_ side: String) {
        logger.debug("Side changed to: \(side)")
        updateUI(for: documentState.currentState)
    }
    
    private func handleError(_ error: String) {
        logger.error("Error occurred: \(error)")
        updateUI(for: .error)
    }
    
    // MARK: - UI Updates
    
    private func updateUI(for state: DocumentModuleState) {
        // Clear current view
        currentView?.removeFromSuperview()
        currentView = nil
        
        // Update title
        if state != .previewing {
            title = "Document"
        }
        
        // Build appropriate view for state
        switch state {
        case .initial:
            showInitialView()
            
        case .capturing:
            showCameraView()
            
        case .previewing:
            showPreviewView()
            
        case .uploading:
            showUploadingView()
            
        case .nfcMrzScan:
            showNFCInputView()
            
        case .nfcReading:
            showNFCReadingView()
            
        case .error:
            showErrorView()
        }
    }
    
    // MARK: - View Builders
    
    private func showInitialView() {
        let initialView = DocumentInitialView(
            side: documentState.currentSide,
            theme: sdkConfig.theme
        )
        
        initialView.onOpenCameraTapped = { [weak self] in
            self?.documentState.currentState = .capturing
        }
        
        addViewToContainer(initialView)
    }
    
    private func showCameraView() {
        let cameraVC = DocumentCameraViewController(
            side: documentState.currentSide,
            qualityThreshold: config.qualityThreshold,
            primaryColor: sdkConfig.theme.colors.primary,
            onImageCaptured: { [weak self] imageData, blurScore in
                guard let self = self else { return }
                
                self.documentState.captureImage(imageData, blurScore: blurScore)
                
                self.dismiss(animated: true) {
                    // State will automatically transition to .previewing
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.documentState.currentState = .initial
                }
            }
        )
        
        let navController = UINavigationController(rootViewController: cameraVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showPreviewView() {
        guard let imageData = (documentState.currentSide == "front" ? 
                                documentState.capturedFrontImage : 
                                documentState.capturedBackImage),
              let image = UIImage(data: imageData) else {
            documentState.currentState = .error
            documentState.errorMessage = "Failed to load captured image"
            return
        }
        
        title = "Preview \(documentState.currentSide.capitalized)"
        
        let previewView = DocumentPreviewView(
            side: documentState.currentSide,
            image: image,
            blurScore: documentState.currentBlurScore,
            theme: sdkConfig.theme
        )
        
        previewView.onRetake = { [weak self] in
            self?.documentState.retakeImage()
        }
        
        previewView.onConfirm = { [weak self] in
            self?.confirmImage()
        }
        
        addViewToContainer(previewView)
    }
    
    private func showUploadingView() {
        let uploadingView = DocumentUploadingView(theme: sdkConfig.theme)
        addViewToContainer(uploadingView)
    }
    
    private func showErrorView() {
        let errorMessage = documentState.errorMessage ?? "An error occurred"
        let errorView = DocumentErrorView(errorMessage: errorMessage, theme: sdkConfig.theme)
        
        errorView.onRetry = { [weak self] in
            self?.documentState.currentState = .capturing
            self?.documentState.errorMessage = nil
        }
        
        errorView.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        addViewToContainer(errorView)
    }
    
    private func addViewToContainer(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        currentView = view
    }
    
    // MARK: - Business Logic Coordination
    
    private func confirmImage() {
        Task {
            documentState.currentState = .uploading
            
            do {
                // Get current side data
                guard let imageData = (documentState.currentSide == "front" ?
                                        documentState.capturedFrontImage :
                                        documentState.capturedBackImage) else {
                    throw OkIDError.documentUploadFailed(reason: "No image captured")
                }
                
                // Upload document using manager
                let response = try await documentManager.uploadDocument(
                    imageData: imageData,
                    side: documentState.currentSide,
                    blurScore: documentState.currentBlurScore
                )
                
                logger.debug("Upload response status: \(response.status)")
                logger.debug("Next step: \(String(describing: response.nextStep))")
                logger.debug("Attempt result: \(response.attemptResult.status)")
                
                // Check rejection first
                if response.attemptResult.status == "rejected" {
                    let reasonCode = response.attemptResult.reasonCode ?? "UNKNOWN"
                    let message = response.attemptResult.message ?? "Image rejected"
                    
                    logger.debug("Image rejected: \(reasonCode) - \(message)")
                    
                    await MainActor.run {
                        documentState.errorMessage = "\(reasonCode): \(message)"
                        showRejectionErrorScreen()
                    }
                    return
                }
                
                // Handle response
                await handleUploadResponse(response)
                
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                OkIDErrorHandler.shared.handle(
                    error,
                    context: "DocumentViewController.confirmImage",
                    severity: .error
                )
                
                documentState.errorMessage = okidError.errorDescription ?? error.localizedDescription
                documentState.currentState = .error
            }
        }
    }
    
    private func handleUploadResponse(_ response: OkIDDocumentModuleResponse) async {
        // Check if we need to capture back side
        let needsBackSide = config.requiresBackSide && documentState.needsBackSide
        
        if needsBackSide {
            documentState.confirmAndProceed(requiresBackSide: true)
            return
        }
        
        // Check if should proceed to NFC
        let shouldNFC = documentManager.shouldProceedToNFC(
            response: response,
            nfcAvailable: documentState.nfcAvailability
        )
        
        if shouldNFC {
            // Extract MRZ credentials
            if let credentials = documentManager.extractMRZCredentials(from: response) {
                documentState.nfcCredentials = credentials
            }
            documentState.currentState = .nfcMrzScan
            return
        }
        
        // Complete
        completeModule(nextStep: response.nextStep)
    }
    
    // MARK: - NFC Flow
    
    private func checkNFCAvailability() {
        documentState.nfcAvailability = documentManager.checkNFCAvailability()
        documentState.nfcChecked = true
        
        if !documentState.nfcAvailability {
            showNFCUnavailableWarning()
        }
    }
    
    private func showNFCUnavailableWarning() {
        let message = """
        This verification may require reading the NFC chip in your passport for enhanced security.
        
        Please enable NFC in Settings > General > NFC.
        """
        
        OkIDAlert.show(
            title: "NFC Required",
            message: message,
            actions: [
                .cancel(handler: nil),
                OkIDAlert.Action(title: "Open Settings", style: .default) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            ],
            from: self
        )
    }
    
    private func showNFCInputView() {
        let inputVC = NFCInputViewController(
            onStart: { [weak self] credentials in
                guard let self = self else { return }
                self.documentState.nfcCredentials = credentials
                self.dismiss(animated: true) {
                    self.documentState.currentState = .nfcReading
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.completeModule(nextStep: nil)
                }
            },
            primaryColor: sdkConfig.theme.colors.primary,
            initialCredentials: documentState.nfcCredentials
        )
        
        let navController = UINavigationController(rootViewController: inputVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showNFCReadingView() {
        guard let credentials = documentState.nfcCredentials else {
            completeModule(nextStep: nil)
            return
        }
        
        documentState.nfcReadStartTime = Date()
        
        let nfcVC = NFCReadingViewController(
            credentials: credentials,
            primaryColor: sdkConfig.theme.colors.primary,
            onSuccess: { [weak self] passportData in
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    Task {
                        await self.handleNFCSuccess(passportData)
                    }
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    logger.error("NFC read error: \(error)")
                    self.completeModule(nextStep: nil)
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.completeModule(nextStep: nil)
                }
            }
        )
        
        let navController = UINavigationController(rootViewController: nfcVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func handleNFCSuccess(_ passportData: OkIDPassportData) async {
        documentState.currentState = .uploading
        
        do {
            let duration = Date().timeIntervalSince(documentState.nfcReadStartTime ?? Date())
            
            _ = try await documentManager.submitNFCData(
                passportData: passportData,
                readDuration: duration,
                usedPace: documentState.usedPace
            )
            
            logger.debug("NFC submission successful")
            completeModule(nextStep: nil)
            
        } catch {
            logger.error("NFC submission failed: \(error)")
            // Continue anyway - NFC is optional
            completeModule(nextStep: nil)
        }
    }
    
    private func autoSubmitProfileNFC() {
        Task {
            do {
                try await documentManager.autoSubmitProfileNFC()
                logger.debug("Profile NFC auto-submitted")
            } catch {
                logger.error("Profile NFC auto-submit failed: \(error)")
                // Continue with normal flow
                documentState.currentState = .nfcMrzScan
            }
        }
    }
    
    // MARK: - Rejection Error Screen
    
    private func showRejectionErrorScreen() {
        // Clear current view
        currentView?.removeFromSuperview()
        currentView = nil
        
        let errorInfo = documentManager.analyzeError(documentState.errorMessage ?? "")
        
        let rejectionView = DocumentRejectionView(
            errorInfo: errorInfo,
            primaryColor: sdkConfig.theme.colors.primary
        )
        
        rejectionView.onTryAgain = { [weak self] in
            self?.documentState.currentState = .capturing
            self?.documentState.errorMessage = nil
        }
        
        addViewToContainer(rejectionView)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        OkIDAlert.showConfirmation(
            title: "Cancel Verification",
            message: "Are you sure you want to cancel the document verification?",
            confirmTitle: "Cancel Verification",
            confirmStyle: .destructive,
            from: self,
            onConfirm: { [weak self] in
                self?.dismiss(animated: true) {
                    logger.debug("Document verification cancelled")
                }
            }
        )
    }
    
    private func completeModule(nextStep: String?) {
        logger.debug("Document module completed. Next: \(nextStep ?? "none")")
        onComplete(nextStep)
    }
}
