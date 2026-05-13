import UIKit

// MARK: - Verification Flow Content View

/// Pure UI view for the verification flow screens
/// Contains: loading screen, error screen, auto-submit progress screen
/// The container for child module VCs is managed by the controller
class VerificationFlowContentView: UIView {
    
    // MARK: - Callbacks
    
    var onRetryTapped: (() -> Void)?
    var onCancelTapped: (() -> Void)?
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let errorColor: UIColor
    
    // MARK: - UI Elements
    
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let loadingLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.text = "Loading verification..."
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor, errorColor: UIColor) {
        self.primaryColor = primaryColor
        self.errorColor = errorColor
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        loadingIndicator.color = primaryColor
    }
    
    // MARK: - Screen Builders
    
    /// Clear container and show loading screen
    func showLoading() {
        clearContainer()
        
        containerView.addSubview(loadingIndicator)
        containerView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 24),
            loadingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        loadingIndicator.startAnimating()
    }
    
    /// Clear container and show error screen
    func showError(message: String) {
        clearContainer()
        
        let errorContainer = UIView()
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let errorIcon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        errorIcon.tintColor = errorColor
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        errorIcon.contentMode = .scaleAspectFit
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "Failed to Load Verification"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = OkIDLabel()
        messageLabel.text = message
        messageLabel.textColor = .gray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = OkIDSecondaryButton(title: "Cancel", titleColor: primaryColor)
        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)
        
        let retryButton = OkIDPrimaryButton(title: "Retry")
        retryButton.addTarget(self, action: #selector(handleRetryTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(retryButton)
        
        errorContainer.addSubview(errorIcon)
        errorContainer.addSubview(titleLabel)
        errorContainer.addSubview(messageLabel)
        errorContainer.addSubview(buttonStack)
        containerView.addSubview(errorContainer)
        
        NSLayoutConstraint.activate([
            errorContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            errorContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            errorContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            errorContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            errorIcon.topAnchor.constraint(equalTo: errorContainer.topAnchor),
            errorIcon.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor),
            errorIcon.widthAnchor.constraint(equalToConstant: 80),
            errorIcon.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: errorIcon.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor),
            
            buttonStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            buttonStack.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            buttonStack.bottomAnchor.constraint(equalTo: errorContainer.bottomAnchor)
        ])
    }
    
    /// Clear container and show auto-submit progress screen
    func showAutoSubmit(message: String?) {
        clearContainer()
        
        let centerContainer = UIView()
        centerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let shieldContainer = UIView()
        shieldContainer.backgroundColor = primaryColor.withAlphaComponent(0.1)
        shieldContainer.layer.cornerRadius = 60
        shieldContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let shieldIcon = UIImageView(image: UIImage(systemName: "shield"))
        shieldIcon.tintColor = primaryColor
        shieldIcon.contentMode = .scaleAspectFit
        shieldIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "Using Saved Profile"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.gray.withAlphaComponent(0.8)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = OkIDLabel()
        messageLabel.text = message ?? "Submitting your saved verification data..."
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = UIColor.gray.withAlphaComponent(0.6)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let progressIndicator = UIActivityIndicatorView(style: .large)
        progressIndicator.color = primaryColor
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.startAnimating()
        
        shieldContainer.addSubview(shieldIcon)
        centerContainer.addSubview(shieldContainer)
        centerContainer.addSubview(titleLabel)
        centerContainer.addSubview(messageLabel)
        centerContainer.addSubview(progressIndicator)
        containerView.addSubview(centerContainer)
        
        NSLayoutConstraint.activate([
            centerContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            centerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            centerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            
            shieldContainer.topAnchor.constraint(equalTo: centerContainer.topAnchor),
            shieldContainer.centerXAnchor.constraint(equalTo: centerContainer.centerXAnchor),
            shieldContainer.widthAnchor.constraint(equalToConstant: 120),
            shieldContainer.heightAnchor.constraint(equalToConstant: 120),
            
            shieldIcon.centerXAnchor.constraint(equalTo: shieldContainer.centerXAnchor),
            shieldIcon.centerYAnchor.constraint(equalTo: shieldContainer.centerYAnchor),
            shieldIcon.widthAnchor.constraint(equalToConstant: 64),
            shieldIcon.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: shieldContainer.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor),
            
            progressIndicator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            progressIndicator.centerXAnchor.constraint(equalTo: centerContainer.centerXAnchor),
            progressIndicator.bottomAnchor.constraint(equalTo: centerContainer.bottomAnchor)
        ])
    }
    
    /// Clear container for module display (controller adds child VC view here)
    func clearForModule() {
        clearContainer()
    }
    
    // MARK: - Private
    
    private func clearContainer() {
        containerView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Actions
    
    @objc private func handleRetryTapped() {
        onRetryTapped?()
    }
    
    @objc private func handleCancelTapped() {
        onCancelTapped?()
    }
}
