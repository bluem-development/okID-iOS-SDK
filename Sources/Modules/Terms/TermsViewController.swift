import UIKit

/// Terms and Conditions module - Controller
/// Thin coordinator between TermsManager (business logic),
/// TermsState (state), and TermsContentView (UI)
@MainActor
public class TermsViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let termsManager: TermsManager
    private let termsState: TermsState
    private let termsView: TermsContentView
    
    // MARK: - Properties
    
    private let sdkConfig: OkIDSDKConfig
    private let onComplete: (String?) -> Void
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        config: OkIDTermsModuleConfig,
        sdkConfig: OkIDSDKConfig,
        onComplete: @escaping (String?) -> Void
    ) {
        self.sdkConfig = sdkConfig
        self.onComplete = onComplete
        
        // Create MVC components
        self.termsManager = TermsManager(
            verificationId: verificationId,
            config: config,
            sdkConfig: sdkConfig
        )
        self.termsState = TermsState()
        self.termsView = TermsContentView(
            theme: sdkConfig.theme,
            acceptanceRequired: config.acceptanceRequired,
            termsContent: config.content,
            buttonTitle: config.acceptanceRequired ? "Accept & Continue" : "Continue"
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Terms & Conditions"
        view.backgroundColor = .white
        navigationItem.hidesBackButton = true
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        setupTermsView()
        bindState()
        updateView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupTermsView() {
        termsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(termsView)
        
        NSLayoutConstraint.activate([
            termsView.topAnchor.constraint(equalTo: view.topAnchor),
            termsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            termsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            termsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Wire view callbacks to controller actions
        termsView.onCheckboxTapped = { [weak self] in
            self?.termsState.toggleAcceptance()
        }
        
        termsView.onContinueTapped = { [weak self] in
            self?.acceptTerms()
        }
    }
    
    private func bindState() {
        termsState.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .idle:
                updateView()
                
            case .submitting:
                termsView.setSubmitting(true, canProceed: false)
                termsView.hideMessages()
                
            case .accepted(let nextStep):
                termsView.setSubmitting(false, canProceed: true)
                onComplete(nextStep)
                
            case .error(let message):
                termsView.setSubmitting(false, canProceed: termsManager.canProceed(isAccepted: termsState.isAccepted))
                termsView.showError(message)
            }
        }
        
        termsState.onAcceptanceChanged = { [weak self] isAccepted in
            guard let self else { return }
            termsView.setAccepted(isAccepted)
            updateView()
        }
    }
    
    // MARK: - View Updates
    
    private func updateView() {
        let canProceed = termsManager.canProceed(isAccepted: termsState.isAccepted)
        termsView.setSubmitting(false, canProceed: canProceed)
        termsView.setAccepted(termsState.isAccepted)
        
        // Show helper when acceptance required but not yet accepted
        if termsManager.acceptanceRequired && !termsState.isAccepted {
            termsView.showHelper()
        } else {
            termsView.hideMessages()
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func acceptTerms() {
        termsState.startSubmitting()
        
        Task {
            do {
                let nextStep = try await termsManager.acceptTerms()
                termsState.completeAcceptance(nextStep: nextStep)
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                termsState.setError(okidError.errorDescription ?? error.localizedDescription)
            }
        }
    }
}

// MARK: - Helper Extension

extension UIColor {
    convenience init(rgb: Int) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
