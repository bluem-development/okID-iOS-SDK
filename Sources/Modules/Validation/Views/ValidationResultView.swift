import UIKit

// MARK: - Validation Loading View

/// Loading screen shown during validation
class ValidationLoadingView: UIView {
    
    private let theme: OkIDThemeConfig
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = OkIDLabel()
    private let messageLabel = OkIDLabel()
    
    init(theme: OkIDThemeConfig) {
        self.theme = theme
        super.init(frame: .zero)
        setupViews()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        
        loadingIndicator.color = theme.colors.primary
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        statusLabel.font = .systemFont(ofSize: 28, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .black
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .okidGray600
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 32),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }
    
    private func configureContent() {
        statusLabel.text = "Validating..."
        messageLabel.text = "Please wait while we verify your information"
    }
}

// MARK: - Validation Result View

/// Result screen showing success/review/rejection
class ValidationResultView: UIView {
    
    private let state: ValidationModuleState
    private let status: String
    private let reason: String?
    private let theme: OkIDThemeConfig
    
    var onAction: (() -> Void)?
    
    private let iconImageView = UIImageView()
    private let statusLabel = OkIDLabel()
    private let messageLabel = OkIDLabel()
    private let actionButton = OkIDPrimaryButton(title: "", icon: nil)
    
    init(state: ValidationModuleState, status: String, reason: String?, theme: OkIDThemeConfig) {
        self.state = state
        self.status = status
        self.reason = reason
        self.theme = theme
        super.init(frame: .zero)
        setupViews()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        statusLabel.font = .systemFont(ofSize: 28, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .black
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .okidGray600
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 32),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }
    
    private func configureContent() {
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        
        switch state {
        case .success:
            iconImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            iconImageView.tintColor = .okidSuccess
            statusLabel.text = "Verification Successful"
            messageLabel.text = "Your verification is complete"
            actionButton.setTitle("Done", for: .normal)
            
        case .needsReview:
            iconImageView.image = UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: config)
            iconImageView.tintColor = .okidWarningIcon
            statusLabel.text = "Under Review"
            messageLabel.text = "Your verification requires manual review. You will be notified of the result."
            actionButton.setTitle("Done", for: .normal)
            
        case .rejected:
            iconImageView.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
            iconImageView.tintColor = .okidError
            statusLabel.text = "Verification Failed"
            messageLabel.text = reason ?? "Verification was rejected"
            actionButton.setTitle("Try Again", for: .normal)
            
        default:
            iconImageView.image = UIImage(systemName: "info.circle.fill", withConfiguration: config)
            iconImageView.tintColor = theme.colors.primary
            statusLabel.text = "Complete"
            messageLabel.text = "Verification status: \(status)"
            actionButton.setTitle("Done", for: .normal)
        }
    }
    
    @objc private func actionTapped() {
        onAction?()
    }
}

// MARK: - Validation Error View

/// Error screen with retry option
class ValidationErrorView: UIView {
    
    private let errorMessage: String
    private let theme: OkIDThemeConfig
    
    var onRetry: (() -> Void)?
    
    private let iconImageView = UIImageView()
    private let statusLabel = OkIDLabel()
    private let messageLabel = OkIDLabel()
    private let retryButton = OkIDPrimaryButton(title: "Try Again", icon: nil)
    
    init(errorMessage: String, theme: OkIDThemeConfig) {
        self.errorMessage = errorMessage
        self.theme = theme
        super.init(frame: .zero)
        setupViews()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        statusLabel.font = .systemFont(ofSize: 28, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .black
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .okidGray600
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 32),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            retryButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            retryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }
    
    private func configureContent() {
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
        iconImageView.tintColor = .okidError
        
        statusLabel.text = "Validation Error"
        messageLabel.text = errorMessage
    }
    
    @objc private func retryTapped() {
        onRetry?()
    }
}
