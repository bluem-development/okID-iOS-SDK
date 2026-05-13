import UIKit

private let logger = Logger.liveness

/// Liveness verification module
/// REFACTORED to follow proper MVC pattern
/// - Uses LivenessState for state management
/// - Uses LivenessManager for business logic
/// - Uses separate View classes for UI
/// - Controller coordinates between Model, View, and business logic
public class LivenessViewController: UIViewController {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDLivenessModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let onComplete: ((String?) -> Void)?
    private let onCancel: (() -> Void)?
    
    // MARK: - MVC Components
    
    private let livenessState: LivenessState
    private let livenessManager: LivenessManager
    
    // MARK: - UI Components
    
    private var cameraVC: LivenessCameraScreen?
    private var currentView: UIView?
    
    // Fake navigation bar
    private let fakeNavBar = UIView()
    private let fakeNavTitleLabel = OkIDLabel()
    private lazy var fakeNavCloseButton: OkIDButton = {
        let icon = UIImage(systemName: "xmark")
        let config = OkIDButtonConfig(
            backgroundColor: .clear,
            titleColor: .white,
            icon: icon,
            height: 30
        )
        let button = OkIDButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var primaryColor: UIColor {
        return sdkConfig.theme.colors.primary
    }
    
    public override var prefersStatusBarHidden: Bool {
        return livenessState.shouldHideStatusBar
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        config: OkIDLivenessModuleConfig,
        sdkConfig: OkIDSDKConfig,
        onComplete: ((String?) -> Void)?,
        onCancel: (() -> Void)? = nil
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.onComplete = onComplete
        self.onCancel = onCancel
        
        // Initialize MVC components
        self.livenessState = LivenessState()
        self.livenessManager = LivenessManager(
            verificationId: verificationId,
            config: config,
            sdkConfig: sdkConfig
        )
        
        super.init(nibName: nil, bundle: nil)
        
        setupStateObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        fakeNavBar.isHidden = true
        fakeNavBar.removeFromSuperview()
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        // Start with camera
        updateUI(for: .capturing)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        setupFakeNavigationBar()
    }
    
    private func setupFakeNavigationBar() {
        fakeNavBar.backgroundColor = primaryColor
        fakeNavBar.isHidden = true
        view.addSubview(fakeNavBar)
        fakeNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        fakeNavTitleLabel.text = "Selfie"
        fakeNavTitleLabel.textColor = .white
        fakeNavTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        fakeNavTitleLabel.textAlignment = .center
        fakeNavBar.addSubview(fakeNavTitleLabel)
        fakeNavTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fakeNavCloseButton.addTarget(self, action: #selector(fakeNavCloseTapped), for: .touchUpInside)
        fakeNavBar.addSubview(fakeNavCloseButton)
        
        NSLayoutConstraint.activate([
            fakeNavBar.topAnchor.constraint(equalTo: view.topAnchor),
            fakeNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fakeNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fakeNavBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            
            fakeNavCloseButton.leadingAnchor.constraint(equalTo: fakeNavBar.leadingAnchor, constant: 16),
            fakeNavCloseButton.bottomAnchor.constraint(equalTo: fakeNavBar.bottomAnchor, constant: -12),
            fakeNavCloseButton.widthAnchor.constraint(equalToConstant: 30),
            fakeNavCloseButton.heightAnchor.constraint(equalToConstant: 30),
            
            fakeNavTitleLabel.centerXAnchor.constraint(equalTo: fakeNavBar.centerXAnchor),
            fakeNavTitleLabel.centerYAnchor.constraint(equalTo: fakeNavCloseButton.centerYAnchor)
        ])
    }
    
    private func setupStateObservers() {
        livenessState.onStateChanged = { [weak self] newState in
            self?.handleStateChange(newState)
        }
        
        livenessState.onStatusBarVisibilityChanged = { [weak self] shouldHide in
            self?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: LivenessModuleState) {
        logger.debug("State changed to: \(state)")
        updateUI(for: state)
    }
    
    // MARK: - UI Updates
    
    private func updateUI(for state: LivenessModuleState) {
        // Clear current view
        currentView?.removeFromSuperview()
        currentView = nil
        
        switch state {
        case .initial, .capturing:
            showCameraView()
            
        case .uploading:
            showUploadingView()
            
        case .error:
            showErrorView()
        }
    }
    
    // MARK: - View Builders
    
    private func showCameraView() {
        livenessState.shouldHideStatusBar = true
        fakeNavBar.isHidden = true
        
        let cameraVC = LivenessCameraScreen(
            onImageCaptured: { [weak self] (imageData: Data, biometrics: [String: Any]?) in
                guard let self = self else { return }
                
                self.livenessState.captureImage(imageData, biometrics: biometrics)
                
                // Upload immediately
                Task {
                    await self.uploadImage()
                }
            },
            onCancel: { [weak self] in
                self?.onCancel?()
            }
        )
        
        self.cameraVC = cameraVC
        
        addChild(cameraVC)
        view.addSubview(cameraVC.view)
        cameraVC.view.frame = view.bounds
        cameraVC.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        cameraVC.didMove(toParent: self)
    }
    
    private func showUploadingView() {
        livenessState.shouldHideStatusBar = false
        
        // Pre-stop the camera to avoid blocking during removal
        cameraVC?.prepareForRemoval()
        
        let uploadingView = LivenessUploadingView(theme: sdkConfig.theme)
        uploadingView.translatesAutoresizingMaskIntoConstraints = false
        uploadingView.alpha = 0
        view.addSubview(uploadingView)
        
        // Show fake nav bar above the uploading view
        fakeNavBar.isHidden = false
        view.bringSubviewToFront(fakeNavBar)
        
        NSLayoutConstraint.activate([
            uploadingView.topAnchor.constraint(equalTo: fakeNavBar.bottomAnchor),
            uploadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uploadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            uploadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentView = uploadingView
        
        // Cross-fade: fade in uploading view, then remove camera
        UIView.animate(withDuration: 0.3, animations: {
            uploadingView.alpha = 1
            self.cameraVC?.view.alpha = 0
        }) { [weak self] _ in
            guard let self else { return }
            self.cameraVC?.willMove(toParent: nil)
            self.cameraVC?.view.removeFromSuperview()
            self.cameraVC?.removeFromParent()
            self.cameraVC = nil
        }
    }
    
    private func showErrorView() {
        livenessState.shouldHideStatusBar = false
        
        // Pre-stop the camera to avoid blocking during removal
        cameraVC?.prepareForRemoval()
        
        let errorMessage = livenessState.errorMessage ?? "Upload failed"
        let errorView = LivenessErrorView(errorMessage: errorMessage, theme: sdkConfig.theme)
        
        errorView.onRetry = { [weak self] in
            self?.livenessState.retryCapture()
        }
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.alpha = 0
        view.addSubview(errorView)
        
        // Show fake nav bar above the error view
        fakeNavBar.isHidden = false
        view.bringSubviewToFront(fakeNavBar)
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: fakeNavBar.bottomAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentView = errorView
        
        // Cross-fade: fade in error view, then remove camera
        UIView.animate(withDuration: 0.3, animations: {
            errorView.alpha = 1
            self.cameraVC?.view.alpha = 0
        }) { [weak self] _ in
            guard let self else { return }
            self.cameraVC?.willMove(toParent: nil)
            self.cameraVC?.view.removeFromSuperview()
            self.cameraVC?.removeFromParent()
            self.cameraVC = nil
        }
    }
    
    // MARK: - Business Logic Coordination
    
    private func uploadImage() async {
        guard let imageData = livenessState.capturedImage else {
            livenessState.setError("No image captured")
            return
        }
        
        do {
            let response = try await livenessManager.uploadSelfie(
                imageData: imageData,
                biometricData: livenessState.biometricData
            )
            
            logger.debug("Liveness upload successful: \(response.status)")
            completeModule(nextStep: response.nextStep)
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "LivenessViewController.uploadImage",
                severity: .error
            )
            
            livenessState.setError(okidError.errorDescription ?? error.localizedDescription)
        }
    }
    
    // MARK: - Actions
    
    @objc private func fakeNavCloseTapped() {
        onCancel?()
    }
    
    private func completeModule(nextStep: String?) {
        logger.debug("Liveness module completed. Next: \(nextStep ?? "none")")
        onComplete?(nextStep)
    }
}
