import UIKit

/// View for displaying document rejection error with tips
/// Extracted from DocumentViewController following MVC pattern
class DocumentRejectionView: UIView {
    
    // MARK: - Callbacks
    
    var onTryAgain: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStack = UIStackView()
    private let buttonContainer = UIView()
    private let tryAgainButton: OkIDButton
    
    // MARK: - Initialization
    
    init(errorInfo: (title: String, message: String, tips: [String]), primaryColor: UIColor) {
        self.tryAgainButton = OkIDButton(config: .primary(color: primaryColor, icon: nil))
        super.init(frame: .zero)
        setupUI(errorInfo: errorInfo, primaryColor: primaryColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(errorInfo: (title: String, message: String, tips: [String]), primaryColor: UIColor) {
        
        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Error container
        let errorContainer = buildErrorContainer(title: errorInfo.title, message: errorInfo.message)
        contentStack.addArrangedSubview(errorContainer)
        
        // Tips container
        let tipsContainer = buildTipsContainer(tips: errorInfo.tips)
        contentStack.addArrangedSubview(tipsContainer)
        
        scrollView.addSubview(contentStack)
        
        // Button container
        buttonContainer.backgroundColor = .white
        buttonContainer.layer.shadowColor = UIColor.black.cgColor
        buttonContainer.layer.shadowOpacity = 0.05
        buttonContainer.layer.shadowRadius = 10
        buttonContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        tryAgainButton.setTitle("Try Again", for: .normal)
        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        tryAgainButton.addTarget(self, action: #selector(tryAgainTapped), for: .touchUpInside)
        buttonContainer.addSubview(tryAgainButton)
        
        addSubview(scrollView)
        addSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            buttonContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 128),
            
            tryAgainButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 16),
            tryAgainButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 16),
            tryAgainButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - UI Builders
    
    private func buildErrorContainer(title: String, message: String) -> UIView {
        let errorContainer = UIView()
        errorContainer.backgroundColor = UIColor.red.withAlphaComponent(0.1)
        errorContainer.layer.borderColor = UIColor.red.withAlphaComponent(0.3).cgColor
        errorContainer.layer.borderWidth = 1
        errorContainer.layer.cornerRadius = 12
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let errorIcon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        errorIcon.tintColor = .red
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let errorStack = UIStackView()
        errorStack.axis = .vertical
        errorStack.spacing = 4
        errorStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = OkIDLabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .red
        titleLabel.numberOfLines = 0
        
        let messageLabel = OkIDLabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.gray
        messageLabel.numberOfLines = 0
        
        errorStack.addArrangedSubview(titleLabel)
        errorStack.addArrangedSubview(messageLabel)
        
        errorContainer.addSubview(errorIcon)
        errorContainer.addSubview(errorStack)
        
        NSLayoutConstraint.activate([
            errorIcon.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor, constant: 16),
            errorIcon.topAnchor.constraint(equalTo: errorContainer.topAnchor, constant: 16),
            errorIcon.widthAnchor.constraint(equalToConstant: 24),
            errorIcon.heightAnchor.constraint(equalToConstant: 24),
            
            errorStack.leadingAnchor.constraint(equalTo: errorIcon.trailingAnchor, constant: 16),
            errorStack.topAnchor.constraint(equalTo: errorContainer.topAnchor, constant: 16),
            errorStack.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor, constant: -16),
            errorStack.bottomAnchor.constraint(equalTo: errorContainer.bottomAnchor, constant: -16)
        ])
        
        return errorContainer
    }
    
    private func buildTipsContainer(tips: [String]) -> UIView {
        let tipsContainer = UIView()
        tipsContainer.backgroundColor = .okidBackgroundLight
        tipsContainer.layer.borderColor = UIColor.okidBorderLight.cgColor
        tipsContainer.layer.borderWidth = 1
        tipsContainer.layer.cornerRadius = 12
        tipsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let tipsStack = UIStackView()
        tipsStack.axis = .vertical
        tipsStack.spacing = 12
        tipsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let tipsTitle = OkIDLabel()
        tipsTitle.text = "Tips to improve:"
        tipsTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        
        tipsStack.addArrangedSubview(tipsTitle)
        
        for tip in tips {
            tipsStack.addArrangedSubview(buildInstruction(tip))
        }
        
        tipsContainer.addSubview(tipsStack)
        
        NSLayoutConstraint.activate([
            tipsStack.topAnchor.constraint(equalTo: tipsContainer.topAnchor, constant: 16),
            tipsStack.leadingAnchor.constraint(equalTo: tipsContainer.leadingAnchor, constant: 16),
            tipsStack.trailingAnchor.constraint(equalTo: tipsContainer.trailingAnchor, constant: -16),
            tipsStack.bottomAnchor.constraint(equalTo: tipsContainer.bottomAnchor, constant: -16)
        ])
        
        return tipsContainer
    }
    
    private func buildInstruction(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let bullet = UIView()
        bullet.backgroundColor = .okidSecondary
        bullet.layer.cornerRadius = 3
        bullet.translatesAutoresizingMaskIntoConstraints = false
        
        let label = OkIDLabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .okidSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(bullet)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            bullet.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bullet.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            bullet.widthAnchor.constraint(equalToConstant: 6),
            bullet.heightAnchor.constraint(equalToConstant: 6),
            
            label.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func tryAgainTapped() {
        onTryAgain?()
    }
}
