import UIKit

/// Validation/results module
/// REFACTORED to follow proper MVC pattern
/// - Uses ValidationState for state management
/// - Uses ValidationManager for business logic
/// - Uses separate View classes for UI
/// - Controller coordinates between Model, View, and business logic
@MainActor
public class ValidationViewController: UIViewController {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let sdkConfig: OkIDSDKConfig
    private let onComplete: (OkIDVerificationResult) -> Void
    private let onRetry: () -> Void
    
    // MARK: - MVC Components
    
    private let validationState: ValidationState
    private let validationManager: ValidationManager
    
    // MARK: - UI Components
    
    private var currentView: UIView?
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        sdkConfig: OkIDSDKConfig,
        onComplete: @escaping (OkIDVerificationResult) -> Void,
        onRetry: @escaping () -> Void
    ) {
        self.verificationId = verificationId
        self.sdkConfig = sdkConfig
        self.onComplete = onComplete
        self.onRetry = onRetry
        
        // Initialize MVC components
        self.validationState = ValidationState()
        self.validationManager = ValidationManager(
            verificationId: verificationId,
            sdkConfig: sdkConfig
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
        view.backgroundColor = .white
        setupNavigationBar()
        
        // Start validation
        validationState.currentState = .validating
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = "Validation"
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    private func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.barTintColor = sdkConfig.theme.colors.primary
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func setupStateObservers() {
        validationState.onStateChanged = { [weak self] newState in
            self?.handleStateChange(newState)
        }
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: ValidationModuleState) {
        switch state {
        case .validating:
            showLoadingView()
            startValidation()
            
        case .success, .needsReview, .rejected:
            showResultView()
            
        case .error:
            showErrorView()
        }
    }
    
    // MARK: - View Builders
    
    private func showLoadingView() {
        currentView?.removeFromSuperview()
        
        let loadingView = ValidationLoadingView(theme: sdkConfig.theme)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentView = loadingView
    }
    
    private func showResultView() {
        currentView?.removeFromSuperview()
        
        guard let status = validationState.status else { return }
        
        let resultView = ValidationResultView(
            state: validationState.currentState,
            status: status,
            reason: validationState.reason,
            theme: sdkConfig.theme
        )
        
        resultView.onAction = { [weak self] in
            self?.handleResultAction()
        }
        
        resultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultView)
        
        NSLayoutConstraint.activate([
            resultView.topAnchor.constraint(equalTo: view.topAnchor),
            resultView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentView = resultView
        
        // Auto-complete after delay for success cases
        if validationState.currentState == .success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.handleResultAction()
            }
        }
    }
    
    private func showErrorView() {
        currentView?.removeFromSuperview()
        
        let errorMessage = validationState.errorMessage ?? "Validation failed"
        let errorView = ValidationErrorView(errorMessage: errorMessage, theme: sdkConfig.theme)
        
        errorView.onRetry = { [weak self] in
            self?.validationState.retryValidation()
        }
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentView = errorView
    }
    
    // MARK: - Business Logic Coordination
    
    private func startValidation() {
        Task {
            do {
                let response = try await validationManager.validateVerification()
                
                // Update state based on response
                switch response.status {
                case "verified":
                    validationState.setSuccess(status: response.status)
                    
                case "needs_manual_review":
                    validationState.setNeedsReview(status: response.status, reason: response.reason)
                    
                case "rejected":
                    validationState.setRejected(status: response.status, reason: response.reason)
                    
                default:
                    validationState.setSuccess(status: response.status)
                }
                
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                validationState.setError(okidError.errorDescription ?? error.localizedDescription)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        // If showing error or rejected, dismiss without confirmation
        if validationState.currentState == .error || validationState.currentState == .rejected {
            let result = OkIDVerificationResult(
                verificationId: verificationId,
                status: validationState.status ?? "cancelled"
            )
            onComplete(result)
            return
        }
        
        // Show confirmation before closing during active validation
        OkIDAlert.showConfirmation(
            title: "Cancel Validation",
            message: "Are you sure you want to cancel the validation?",
            confirmTitle: "Cancel Validation",
            confirmStyle: .destructive,
            from: self,
            onConfirm: { [weak self] in
                guard let self = self else { return }
                let result = OkIDVerificationResult(
                    verificationId: self.verificationId,
                    status: self.validationState.status ?? "cancelled"
                )
                self.onComplete(result)
            }
        )
    }
    
    private func handleResultAction() {
        if validationState.currentState == .rejected {
            // Retry verification
            onRetry()
        } else {
            // Complete with current status
            let result = OkIDVerificationResult(
                verificationId: verificationId,
                status: validationState.status ?? "completed"
            )
            onComplete(result)
        }
    }
}
