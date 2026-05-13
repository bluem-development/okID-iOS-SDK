import UIKit

/// PIN flow types
public enum PinFlowType {
    case verify             // Just verify existing PIN
    case setup              // Full setup flow (enter + confirm)
    case change             // Full change flow (verify old + enter new + confirm new)
    case disable            // Verify PIN to disable
}

/// PIN screen — thin coordinator following MVC pattern
/// - Uses PinFlowManager for business logic (validation, storage, step transitions)
/// - Uses PinContentView for all UI
/// - Controller coordinates between them
public class PinViewController: UIViewController {
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let onComplete: ((Bool) -> Void)?
    
    // MARK: - MVC Components
    
    private let flowManager: PinFlowManager
    private var contentView: PinContentView!
    
    // MARK: - State
    
    private var pin: [String] = []
    
    // MARK: - Initialization
    
    public init(
        flowType: PinFlowType,
        primaryColor: UIColor,
        onComplete: @escaping (Bool) -> Void
    ) {
        self.primaryColor = primaryColor
        self.onComplete = onComplete
        self.flowManager = PinFlowManager(flowType: flowType)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindCallbacks()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Navigation bar
        navigationItem.title = flowManager.getTitleForMode()
        updateCloseButtonIcon()
        
        // Content view
        contentView = PinContentView(
            primaryColor: primaryColor,
            showForgotButton: flowManager.shouldShowForgotButton()
        )
        contentView.subtitleLabel.text = flowManager.getSubtitleForMode()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func bindCallbacks() {
        contentView.onDigitTapped = { [weak self] digit in
            self?.handleDigitTapped(digit)
        }
        
        contentView.onBackspaceTapped = { [weak self] in
            self?.handleBackspace()
        }
        
        contentView.onForgotPinTapped = { [weak self] in
            self?.handleForgotPin()
        }
    }
    
    // MARK: - Input Handling
    
    private func handleDigitTapped(_ digit: String) {
        guard pin.count < PinContentView.pinLength else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        pin.append(digit)
        contentView.clearError()
        contentView.updatePinDots(filledCount: pin.count, isError: false)
        
        if pin.count == PinContentView.pinLength {
            handlePinComplete()
        }
    }
    
    private func handleBackspace() {
        guard !pin.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        pin.removeLast()
        contentView.clearError()
        contentView.updatePinDots(filledCount: pin.count, isError: false)
    }
    
    private func handlePinComplete() {
        let enteredPin = pin.joined()
        
        Task {
            let result = await flowManager.handlePinComplete(enteredPin)
            
            await MainActor.run {
                switch result {
                case .flowComplete:
                    onComplete?(true)
                    
                case .nextStep:
                    flowManager.advanceStep()
                    transitionToNextStep()
                    
                case .error(let errorMessage):
                    showPinError(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Flow Transitions
    
    private func transitionToNextStep() {
        pin.removeAll()
        
        // Update UI for new step
        navigationItem.title = flowManager.getTitleForMode()
        contentView.subtitleLabel.text = flowManager.getSubtitleForMode()
        contentView.updatePinDots(filledCount: 0, isError: false)
        contentView.clearError()
        updateCloseButtonIcon()
        
        // Animate transition
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {})
    }
    
    private func showPinError(_ message: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        pin.removeAll()
        contentView.updatePinDots(filledCount: 0, isError: true)
        contentView.showError(message)
    }
    
    private func updateCloseButtonIcon() {
        if flowManager.canGoBack {
            navigationItem.leftBarButtonItem = OkIDBarButtonItem.back(
                target: self,
                action: #selector(closeTapped)
            )
        } else {
            navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
                target: self,
                action: #selector(closeTapped)
            )
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        if flowManager.canGoBack {
            flowManager.goBack()
            transitionToNextStep()
        } else {
            onComplete?(false)
        }
    }
    
    private func handleForgotPin() {
        OkIDAlert.showDestructiveConfirmation(
            title: "Forgot PIN?",
            message: "If you forgot your PIN, you can reset it by deleting your Identity Vault. This will permanently delete all your saved verification data.",
            destructiveTitle: "Delete Vault",
            from: self,
            onConfirm: { [weak self] in
                Task {
                    await self?.flowManager.deletePinAndReset()
                    await MainActor.run {
                        self?.dismiss(animated: true)
                    }
                }
            }
        )
    }
}
