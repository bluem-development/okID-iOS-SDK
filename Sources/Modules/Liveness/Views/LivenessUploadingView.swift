import UIKit

// MARK: - Liveness Uploading View

/// Loading screen shown during selfie upload
/// Extracted from LivenessViewController following proper MVC pattern
class LivenessUploadingView: UIView {
    
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
        contentStack.alignment = .center
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.color = .okidGray600
        spinner.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        spinner.startAnimating()
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 8
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        
        contentStack.addArrangedSubview(spinner)
        contentStack.addArrangedSubview(textStack)
        
        addSubview(contentStack)
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
        titleLabel.text = "Uploading selfie"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .okidTextDark
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Please wait..."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .okidGray600
        subtitleLabel.textAlignment = .center
    }
}

// MARK: - Liveness Error View

/// Error screen with retry option
/// Extracted from LivenessViewController following proper MVC pattern
class LivenessErrorView: UIView {
    
    // MARK: - Properties
    
    private let errorMessage: String
    private let theme: OkIDThemeConfig
    
    var onRetry: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStack = UIStackView()
    private let errorCard = UIView()
    private let errorIcon = UIImageView()
    private let errorTitleLabel = OkIDLabel()
    private let errorMessageLabel = OkIDLabel()
    private let buttonContainer = UIView()
    private let retryButton: OkIDPrimaryButton
    
    // MARK: - Initialization
    
    init(errorMessage: String, theme: OkIDThemeConfig) {
        self.errorMessage = errorMessage
        self.theme = theme
        self.retryButton = OkIDPrimaryButton(title: "Try Again", icon: nil)
        
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
        
        scrollView.backgroundColor = .white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Top spacer
        let topSpacer = UIView()
        topSpacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(topSpacer)
        
        // Error card
        errorCard.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorCard.layer.cornerRadius = 12
        errorCard.layer.borderWidth = 1
        errorCard.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        errorCard.translatesAutoresizingMaskIntoConstraints = false
        
        let cardContent = UIView()
        cardContent.translatesAutoresizingMaskIntoConstraints = false
        errorCard.addSubview(cardContent)
        
        errorIcon.image = UIImage(systemName: "exclamationmark.circle")
        errorIcon.tintColor = .systemRed
        errorIcon.contentMode = .scaleAspectFit
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        cardContent.addSubview(errorIcon)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        textStack.addArrangedSubview(errorTitleLabel)
        textStack.addArrangedSubview(errorMessageLabel)
        cardContent.addSubview(textStack)
        
        contentStack.addArrangedSubview(errorCard)
        scrollView.addSubview(contentStack)
        
        // Button container
        buttonContainer.backgroundColor = .white
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        buttonContainer.addSubview(retryButton)
        
        addSubview(scrollView)
        addSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            cardContent.topAnchor.constraint(equalTo: errorCard.topAnchor, constant: 16),
            cardContent.leadingAnchor.constraint(equalTo: errorCard.leadingAnchor, constant: 16),
            cardContent.trailingAnchor.constraint(equalTo: errorCard.trailingAnchor, constant: -16),
            cardContent.bottomAnchor.constraint(equalTo: errorCard.bottomAnchor, constant: -16),
            
            errorIcon.topAnchor.constraint(equalTo: cardContent.topAnchor),
            errorIcon.leadingAnchor.constraint(equalTo: cardContent.leadingAnchor),
            errorIcon.widthAnchor.constraint(equalToConstant: 24),
            errorIcon.heightAnchor.constraint(equalToConstant: 24),
            
            textStack.topAnchor.constraint(equalTo: cardContent.topAnchor),
            textStack.leadingAnchor.constraint(equalTo: errorIcon.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: cardContent.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: cardContent.bottomAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            buttonContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            retryButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 16),
            retryButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 16),
            retryButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16),
            retryButton.bottomAnchor.constraint(equalTo: buttonContainer.safeAreaLayoutGuide.bottomAnchor, constant: -56)
        ])
    }
    
    private func configureContent() {
        errorTitleLabel.text = "Upload failed"
        errorTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        errorTitleLabel.textColor = .systemRed
        errorTitleLabel.numberOfLines = 0
        
        errorMessageLabel.text = errorMessage
        errorMessageLabel.font = .systemFont(ofSize: 14)
        errorMessageLabel.textColor = .okidTextSecondary
        errorMessageLabel.numberOfLines = 0
    }
    
    // MARK: - Actions
    
    @objc private func retryTapped() {
        onRetry?()
    }
}
