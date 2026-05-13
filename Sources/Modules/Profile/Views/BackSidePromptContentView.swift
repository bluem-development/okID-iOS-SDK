import UIKit

/// Content view for back side prompt — all UI elements
/// Extracted from BackSidePromptViewController following MVC pattern
class BackSidePromptContentView: UIView {
    
    // MARK: - Callbacks
    
    var onCaptureBack: (() -> Void)?
    var onSkipBack: (() -> Void)?
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        super.init(frame: .zero)
        setupUI(primaryColor: primaryColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(primaryColor: UIColor) {
        backgroundColor = .white
        
        // Content container
        let contentView = UIView()
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Success icon container
        let iconContainer = UIView()
        iconContainer.backgroundColor = .okidSuccessLight
        iconContainer.layer.cornerRadius = 64
        
        let iconImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconImageView.tintColor = .okidSuccess
        iconImageView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        let titleLabel = OkIDLabel()
        titleLabel.text = "Front Side Captured"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .okidTextPrimary
        titleLabel.textAlignment = .center
        
        // Description label
        let descLabel = OkIDLabel()
        descLabel.text = "Would you like to capture the back side of your document?"
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = .okidTextSecondary
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        // Optional info label
        let infoLabel = OkIDLabel()
        infoLabel.text = "This is optional for passports but recommended for ID cards."
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .okidTextTertiary
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        
        // Text stack
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descLabel, infoLabel])
        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.setCustomSpacing(8, after: descLabel)
        
        // Icon and text stack
        let mainStack = UIStackView(arrangedSubviews: [iconContainer, textStack])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons container
        let buttonsContainer = UIView()
        buttonsContainer.backgroundColor = .white
        buttonsContainer.layer.shadowColor = UIColor.black.cgColor
        buttonsContainer.layer.shadowOpacity = 0.05
        buttonsContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        buttonsContainer.layer.shadowRadius = 10
        addSubview(buttonsContainer)
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Capture Back button
        let captureButton = OkIDPrimaryButton(title: "Capture Back Side", icon: "camera.fill")
        captureButton.addTarget(self, action: #selector(captureBackTapped), for: .touchUpInside)
        buttonsContainer.addSubview(captureButton)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Skip button
        let skipButton = OkIDSecondaryButton(
            title: "Skip Back Side",
            borderColor: primaryColor,
            titleColor: primaryColor
        )
        skipButton.addTarget(self, action: #selector(skipBackTapped), for: .touchUpInside)
        buttonsContainer.addSubview(skipButton)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            
            mainStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            iconContainer.widthAnchor.constraint(equalToConstant: 128),
            iconContainer.heightAnchor.constraint(equalToConstant: 128),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            
            textStack.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            buttonsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            captureButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor, constant: 16),
            captureButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor, constant: 20),
            captureButton.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor, constant: -20),
            
            skipButton.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 12),
            skipButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor, constant: -20),
            skipButton.bottomAnchor.constraint(equalTo: buttonsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func captureBackTapped() {
        onCaptureBack?()
    }
    
    @objc private func skipBackTapped() {
        onSkipBack?()
    }
}
