import UIKit

// MARK: - Document Preview View

/// Preview screen for captured document image
/// Extracted from DocumentViewController following proper MVC pattern
internal class DocumentPreviewView: UIView {
    
    // MARK: - Properties
    
    private let side: String
    private let image: UIImage
    private let blurScore: Double?
    private let theme: OkIDThemeConfig
    
    var onRetake: (() -> Void)?
    var onConfirm: (() -> Void)?
    
    // MARK: - UI Components
    
    private let imageView = UIImageView()
    private let qualityCard = UIView()
    private let qualityStack = UIStackView()
    private let qualityIconView = UIImageView()
    private let qualityLabel = OkIDLabel()
    private let buttonContainer = UIView()
    private let buttonStack = UIStackView()
    private let confirmButton: OkIDButton
    private let retakeButton: OkIDButton
    
    // MARK: - Initialization
    
    init(side: String, image: UIImage, blurScore: Double?, theme: OkIDThemeConfig) {
        self.side = side
        self.image = image
        self.blurScore = blurScore
        self.theme = theme
        
        let checkIcon = UIImage(systemName: "checkmark")
        self.confirmButton = OkIDButton(config: .primary(color: theme.colors.primary, icon: checkIcon))
        
        // Create retake button config with primary color
        let retakeIcon = UIImage(systemName: "arrow.clockwise")?.withTintColor(theme.colors.primary, renderingMode: .alwaysOriginal)
        let retakeConfig = OkIDButtonConfig(
            backgroundColor: .white,
            titleColor: theme.colors.primary,
            borderWidth: 1.5,
            borderColor: theme.colors.primary,
            icon: retakeIcon
        )
        self.retakeButton = OkIDButton(config: retakeConfig)
        
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
        
        // Image view
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Quality card
        qualityCard.backgroundColor = .white
        qualityCard.layer.borderWidth = 1.5
        qualityCard.layer.cornerRadius = 14  // Match retake button radius
        qualityCard.translatesAutoresizingMaskIntoConstraints = false
        
        qualityStack.axis = .horizontal
        qualityStack.spacing = 8
        qualityStack.alignment = .center
        qualityStack.translatesAutoresizingMaskIntoConstraints = false
        
        qualityIconView.contentMode = .scaleAspectFit
        qualityIconView.translatesAutoresizingMaskIntoConstraints = false
        
        qualityLabel.font = .systemFont(ofSize: 16, weight: .medium)
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Button stack (horizontal layout)
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fill  // Changed from fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Button container - white background area for quality + buttons
        buttonContainer.backgroundColor = .white
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        confirmButton.setTitle("Use Photo", for: .normal)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        retakeButton.setTitle("", for: .normal)  // Icon only
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
        
        // Add subviews
        qualityStack.addArrangedSubview(qualityIconView)
        qualityStack.addArrangedSubview(qualityLabel)
        qualityCard.addSubview(qualityStack)
        
        buttonStack.addArrangedSubview(retakeButton)
        buttonStack.addArrangedSubview(confirmButton)
        
        // Add quality card and button stack to container
        buttonContainer.addSubview(qualityCard)
        buttonContainer.addSubview(buttonStack)
        
        addSubview(imageView)
        addSubview(buttonContainer)
    }
    
    private func setupConstraints() {
        // Create a main vertical stack to center all content together
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Move image and button container into main stack
        imageView.removeFromSuperview()
        buttonContainer.removeFromSuperview()
        
        addSubview(mainStack)
        mainStack.addArrangedSubview(imageView)
        mainStack.addArrangedSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            // Main stack - vertically centered in the view
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Image view - ID card ratio
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.63),
            
            // Quality card - inside white container, higher position
            qualityCard.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 30),
            qualityCard.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            
            qualityStack.topAnchor.constraint(equalTo: qualityCard.topAnchor, constant: 12),
            qualityStack.leadingAnchor.constraint(equalTo: qualityCard.leadingAnchor, constant: 16),
            qualityStack.trailingAnchor.constraint(equalTo: qualityCard.trailingAnchor, constant: -16),
            qualityStack.bottomAnchor.constraint(equalTo: qualityCard.bottomAnchor, constant: -12),
            
            qualityIconView.widthAnchor.constraint(equalToConstant: 20),
            qualityIconView.heightAnchor.constraint(equalToConstant: 20),
            
            // Button stack - below quality card, higher position
            buttonStack.topAnchor.constraint(equalTo: qualityCard.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: buttonContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
            
            // Retake button - fixed smaller width
            retakeButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func configureContent() {
        // Determine quality
        let isGoodQuality = blurScore.map { $0 >= 7.0 } ?? false
        
        // Format quality text with score
        let scoreText = blurScore.map { String(format: " (%.1f)", $0) } ?? ""
        
        if isGoodQuality {
            qualityCard.layer.borderColor = theme.colors.accent.cgColor
            qualityIconView.image = UIImage(systemName: "checkmark.circle.fill")
            qualityIconView.tintColor = theme.colors.accent
            qualityLabel.text = "Good Quality\(scoreText)"
            qualityLabel.textColor = theme.colors.accent
        } else {
            qualityCard.layer.borderColor = theme.colors.warning.cgColor
            qualityIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            qualityIconView.tintColor = theme.colors.warning
            qualityLabel.text = "Quality Warning\(scoreText)"
            qualityLabel.textColor = theme.colors.warning
        }
    }
    
    // MARK: - Actions
    
    @objc private func confirmTapped() {
        onConfirm?()
    }
    
    @objc private func retakeTapped() {
        onRetake?()
    }
}
