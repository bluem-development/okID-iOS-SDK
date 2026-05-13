import UIKit
import Foundation

private let logger = Logger.flow

/// Verification flow controller - manages module navigation
/// MVC-compliant thin controller:
///   Model:  VerificationFlowManager (initialization, auto-submit, config parsing, profile)
///   View:   VerificationFlowContentView (loading, error, auto-submit screens)
///   State:  VerificationFlowState (flow state, profile, completion tracking)
/// Controller handles: navigation, child VC management, state-to-view binding
public class VerificationFlowController: UIViewController {
    
    // MARK: - MVC Components
    
    private let flowState: VerificationFlowState
    private let flowManager: VerificationFlowManager
    private let contentView: VerificationFlowContentView
    
    // MARK: - Properties
    
    private let verificationId: String
    private let sdkConfig: OkIDSDKConfig
    private let callbacks: OkIDVerificationCallbacks?
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        config: OkIDSDKConfig,
        callbacks: OkIDVerificationCallbacks? = nil,
        initialFlow: [String]? = nil,
        initialModules: [String: Any]? = nil,
        desktopSessionId: String? = nil,
        portalBaseUrl: String? = nil
    ) {
        self.verificationId = verificationId
        self.sdkConfig = config
        self.callbacks = callbacks
        
        self.flowState = VerificationFlowState()
        self.flowManager = VerificationFlowManager(
            verificationId: verificationId,
            sdkConfig: config,
            callbacks: callbacks,
            initialFlow: initialFlow,
            initialModules: initialModules,
            desktopSessionId: desktopSessionId,
            portalBaseUrl: portalBaseUrl,
            state: flowState
        )
        self.contentView = VerificationFlowContentView(
            primaryColor: config.theme.colors.primary ?? .okidPrimary,
            errorColor: config.theme.colors.error ?? .okidError
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupContentView()
        bindState()
        bindCallbacks()
        
        flowManager.initializeDesktopNotifier()
        
        Task {
            await flowManager.loadProfileThenInitialize()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        flowManager.cleanupNotifier()
        flowManager.handleDeinitCancel()
    }
    
    // MARK: - Setup
    
    private func setupContentView() {
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    // MARK: - Binding
    
    private func bindState() {
        flowState.onUIUpdateNeeded = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
    }
    
    private func bindCallbacks() {
        contentView.onRetryTapped = { [weak self] in
            Task {
                await self?.flowManager.initializeVerification()
            }
        }
        
        contentView.onCancelTapped = { [weak self] in
            self?.flowManager.handleCancel()
            self?.dismiss(animated: true)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        // Remove existing child VCs
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if flowState.shouldShowLoading {
            contentView.showLoading()
        } else if flowState.shouldShowError, let errorMessage = flowState.errorMessage {
            contentView.showError(message: errorMessage)
        } else if flowState.shouldShowAutoSubmit {
            contentView.showAutoSubmit(message: flowState.autoSubmitMessage)
        } else {
            contentView.clearForModule()
            buildCurrentModule()
        }
    }
    
    // MARK: - Module Building
    
    private func buildCurrentModule() {
        guard let currentModule = flowState.currentModule else { return }
        
        switch currentModule {
        case "terms":
            let config = flowManager.parseTermsConfig(flowState.modules["terms"])
            let termsModule = TermsViewController(
                verificationId: verificationId,
                config: config,
                sdkConfig: sdkConfig
            ) { [weak self] nextStep in
                self?.flowManager.handleModuleComplete(module: "terms", nextStep: nextStep)
            }
            showModule(termsModule)
            
        case "document":
            if flowManager.shouldUseProfileForModule("document") {
                flowState.isAutoSubmitting = true
                flowState.autoSubmitMessage = "Submitting your ID document..."
                Task { await flowManager.autoSubmitDocument() }
                return
            }
            let config = flowManager.parseDocumentConfig(flowState.modules["document"])
            let profileNfcData = flowManager.shouldUseProfileForModule("nfc") ? flowState.profile?.nfc : nil
            let documentModule = DocumentViewController(
                verificationId: verificationId,
                config: config,
                sdkConfig: sdkConfig,
                profileNfcData: profileNfcData
            ) { [weak self] nextStep in
                self?.flowManager.handleModuleComplete(module: "document", nextStep: nextStep)
            }
            showModule(documentModule)
            
        case "liveness":
            if flowManager.shouldUseProfileForModule("liveness") {
                flowState.isAutoSubmitting = true
                flowState.autoSubmitMessage = "Submitting your selfie..."
                Task { await flowManager.autoSubmitLiveness() }
                return
            }
            let config = flowManager.parseLivenessConfig(flowState.modules["liveness"])
            let livenessModule = LivenessViewController(
                verificationId: verificationId,
                config: config,
                sdkConfig: sdkConfig,
                onComplete: { [weak self] nextStep in
                    self?.flowManager.handleModuleComplete(module: "liveness", nextStep: nextStep)
                },
                onCancel: { [weak self] in
                    logger.debug("Liveness cancelled by user")
                    self?.flowManager.handleCancel()
                    self?.dismiss(animated: true)
                }
            )
            showModule(livenessModule)
            
        case "nfc":
            if flowManager.shouldUseProfileForModule("nfc") {
                flowState.isAutoSubmitting = true
                flowState.autoSubmitMessage = "Submitting passport chip data..."
                Task { await flowManager.autoSubmitNfc() }
                return
            }
            showUnknownModuleError("NFC module requires profile data or document flow")
            
        case "form_data":
            let config = flowManager.parseFormDataConfig(flowState.modules["form_data"])
            let formModule = FormDataViewController(
                verificationId: verificationId,
                config: config,
                sdkConfig: sdkConfig
            ) { [weak self] nextStep in
                self?.flowManager.handleModuleComplete(module: "form_data", nextStep: nextStep)
            }
            showModule(formModule)
            
        case "validation":
            let validationModule = ValidationViewController(
                verificationId: verificationId,
                sdkConfig: sdkConfig,
                onComplete: { [weak self] result in
                    self?.flowManager.handleValidationComplete(result: result)
                    self?.dismiss(animated: true)
                },
                onRetry: { [weak self] in
                    self?.flowManager.handleRetry()
                    self?.dismiss(animated: true)
                }
            )
            showModule(validationModule)
            
        default:
            showUnknownModuleError("Unknown module: \(currentModule)")
        }
    }
    
    // MARK: - Child VC Management
    
    private func showModule(_ viewController: UIViewController) {
        if viewController is DocumentViewController || viewController is TermsViewController ||
            viewController is FormDataViewController || viewController is ValidationViewController {
            let navController = UINavigationController(rootViewController: viewController)
            navController.modalPresentationStyle = .fullScreen
            addChild(navController)
            contentView.containerView.addSubview(navController.view)
            navController.view.frame = contentView.containerView.bounds
            navController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navController.didMove(toParent: self)
        } else {
            addChild(viewController)
            contentView.containerView.addSubview(viewController.view)
            viewController.view.frame = contentView.containerView.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewController.didMove(toParent: self)
        }
    }
    
    private func showUnknownModuleError(_ message: String) {
        let errorLabel = OkIDLabel()
        errorLabel.text = message
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let okButton = OkIDPrimaryButton(title: "OK")
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(unknownModuleOKTapped), for: .touchUpInside)
        
        contentView.containerView.addSubview(errorLabel)
        contentView.containerView.addSubview(okButton)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: contentView.containerView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: contentView.containerView.centerYAnchor, constant: -30),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.containerView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.containerView.trailingAnchor, constant: -20),
            
            okButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            okButton.centerXAnchor.constraint(equalTo: contentView.containerView.centerXAnchor),
            okButton.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    @objc private func unknownModuleOKTapped() {
        dismiss(animated: true)
    }
}
