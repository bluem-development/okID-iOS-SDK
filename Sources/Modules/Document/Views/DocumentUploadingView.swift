import UIKit

// MARK: - Document Uploading View

/// Loading screen shown during document upload
/// Extracted from DocumentViewController following proper MVC pattern
internal class DocumentUploadingView: UIView {
    
    // MARK: - Properties
    
    private let theme: OkIDThemeConfig
    
    // MARK: - UI Components
    
    private let contentStack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let titleLabel = OkIDLabel()
    private let subtitleLabel = OkIDLabel()
    
    // MARK: - Initialization
    
    init(theme: OkIDThemeConfig) {
        self.theme = theme
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .white
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.color = theme.colors.primary
        spinner.startAnimating()
        
        addSubview(contentStack)
        contentStack.addArrangedSubview(spinner)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = "Uploading Document"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Please wait while we process your document..."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .okidSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
    }
}

// MARK: - Document Error View

/// Error screen with retry option
/// Extracted from DocumentViewController following proper MVC pattern
internal class DocumentErrorView: UIView {
    
    // MARK: - Properties
    
    private let errorMessage: String
    private let theme: OkIDThemeConfig
    
    var onRetry: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStack = UIStackView()
    private let errorCard = UIView()
    private let errorIcon = UIImageView()
    private let errorTitleLabel = OkIDLabel()
    private let errorMessageLabel = OkIDLabel()
    private let buttonStack = UIStackView()
    private let retryButton: OkIDButton
    private let cancelButton: OkIDButton
    
    // MARK: - Initialization
    
    init(errorMessage: String, theme: OkIDThemeConfig) {
        self.errorMessage = errorMessage
        self.theme = theme
        
        self.retryButton = OkIDButton(config: .primary(color: theme.colors.primary, icon: nil))
        self.cancelButton = OkIDButton(config: .secondary(icon: nil))
        
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .white
        
        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = 32
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Error card
        errorCard.backgroundColor = theme.colors.error.withAlphaComponent(0.1)
        errorCard.layer.borderWidth = 2
        errorCard.layer.borderColor = theme.colors.error.cgColor
        errorCard.layer.cornerRadius = 16
        errorCard.translatesAutoresizingMaskIntoConstraints = false
        
        errorIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        errorIcon.tintColor = theme.colors.error
        errorIcon.contentMode = .scaleAspectFit
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        
        errorCard.addSubview(errorIcon)
        errorCard.addSubview(errorTitleLabel)
        errorCard.addSubview(errorMessageLabel)
        
        // Button stack
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(retryButton)
        buttonStack.addArrangedSubview(cancelButton)
        
        contentStack.addArrangedSubview(errorCard)
        contentStack.addArrangedSubview(buttonStack)
        
        scrollView.addSubview(contentStack)
        addSubview(scrollView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            errorCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            
            errorIcon.topAnchor.constraint(equalTo: errorCard.topAnchor, constant: 32),
            errorIcon.centerXAnchor.constraint(equalTo: errorCard.centerXAnchor),
            errorIcon.widthAnchor.constraint(equalToConstant: 48),
            errorIcon.heightAnchor.constraint(equalToConstant: 48),
            
            errorTitleLabel.topAnchor.constraint(equalTo: errorIcon.bottomAnchor, constant: 16),
            errorTitleLabel.leadingAnchor.constraint(equalTo: errorCard.leadingAnchor, constant: 24),
            errorTitleLabel.trailingAnchor.constraint(equalTo: errorCard.trailingAnchor, constant: -24),
            
            errorMessageLabel.topAnchor.constraint(equalTo: errorTitleLabel.bottomAnchor, constant: 8),
            errorMessageLabel.leadingAnchor.constraint(equalTo: errorCard.leadingAnchor, constant: 24),
            errorMessageLabel.trailingAnchor.constraint(equalTo: errorCard.trailingAnchor, constant: -24),
            errorMessageLabel.bottomAnchor.constraint(equalTo: errorCard.bottomAnchor, constant: -32),
            
            buttonStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        ])
    }
    
    private func configureContent() {
        errorTitleLabel.text = "Upload Failed"
        errorTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        errorTitleLabel.textColor = theme.colors.error
        errorTitleLabel.textAlignment = .center
        errorTitleLabel.numberOfLines = 0
        
        errorMessageLabel.text = errorMessage
        errorMessageLabel.font = .systemFont(ofSize: 15)
        errorMessageLabel.textColor = .okidSecondary
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.numberOfLines = 0
    }
    
    // MARK: - Actions
    
    @objc private func retryTapped() {
        onRetry?()
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
}
