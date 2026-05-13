import UIKit

// MARK: - Profile Dashboard Content View

/// Thin composer view for the Profile Dashboard
/// Assembles sub-views: ProfileTitleSectionView, ProfileProgressView,
/// ProfileModuleCardView, ProfileSecurityToggleView
/// No manager dependency — receives pre-computed display data from the controller
class ProfileDashboardContentView: UIView {
    
    // MARK: - Callbacks
    
    var onModuleCardTapped: ((String) -> Void)?
    var onSecurityToggleTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStack = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        self.primaryColor = primaryColor
        super.init(frame: .zero)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        backgroundColor = .clear
        
        loadingIndicator.color = primaryColor
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    
    func setLoading(_ loading: Bool) {
        if loading {
            loadingIndicator.startAnimating()
            scrollView.isHidden = true
        } else {
            loadingIndicator.stopAnimating()
            scrollView.isHidden = false
        }
    }
    
    /// Rebuild all content using pre-computed display data
    func buildContent(data: ProfileDashboardDisplayData) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Title section
        let titleView = ProfileTitleSectionView(data: data.titleData)
        contentStack.addArrangedSubview(titleView)
        contentStack.setCustomSpacing(32, after: titleView)
        
        // Progress indicator
        let progressView = ProfileProgressView(data: data.progressData)
        contentStack.addArrangedSubview(progressView)
        contentStack.setCustomSpacing(32, after: progressView)
        
        // Module cards
        for (index, cardData) in data.moduleCards.enumerated() {
            let cardView = ProfileModuleCardView(data: cardData)
            cardView.onTapped = { [weak self] moduleKey in
                self?.onModuleCardTapped?(moduleKey)
            }
            contentStack.addArrangedSubview(cardView)
            
            // Extra spacing after the last card
            if index == data.moduleCards.count - 1 {
                contentStack.setCustomSpacing(32, after: cardView)
            }
        }
        
        // Security toggle
        let securityView = ProfileSecurityToggleView(data: data.securityToggle)
        securityView.onToggleTapped = { [weak self] in
            self?.onSecurityToggleTapped?()
        }
        contentStack.addArrangedSubview(securityView)
    }
    
    /// Show a temporary toast message
    func showMessage(_ message: String, type: MessageType) {
        let backgroundColor: UIColor
        switch type {
        case .success:
            backgroundColor = .okidSuccess
        case .warning:
            backgroundColor = .okidWarning
        case .error:
            backgroundColor = .okidErrorDark
        }
        
        let messageView = UIView()
        messageView.backgroundColor = backgroundColor
        messageView.layer.cornerRadius = 12
        messageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = OkIDLabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        messageView.addSubview(label)
        
        addSubview(messageView)
        
        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            messageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            label.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -12)
        ])
        
        messageView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            messageView.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3, animations: {
                messageView.alpha = 0
            }) { _ in
                messageView.removeFromSuperview()
            }
        }
    }
    
    enum MessageType {
        case success
        case warning
        case error
    }
}

// MARK: - Gradient View Helper

class GradientView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    
    init(colors: [UIColor]) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
