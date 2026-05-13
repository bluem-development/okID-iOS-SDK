import UIKit

/// PIN protection toggle for the Profile Dashboard
/// Receives pre-computed display data — no manager dependency
/// Extracted from ProfileDashboardContentView following MVC pattern
class ProfileSecurityToggleView: UIView {
    
    // MARK: - Callbacks
    
    var onToggleTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    init(data: ProfileSecurityToggleData) {
        super.init(frame: .zero)
        buildUI(data: data)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private func buildUI(data: ProfileSecurityToggleData) {
        let isPinEnabled = data.isPinEnabled
        let primaryColor = data.primaryColor
        
        let container = UIButton(type: .custom)
        container.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        container.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        
        let iconContainer = UIView()
        iconContainer.backgroundColor = isPinEnabled ? primaryColor.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 12
        iconContainer.isUserInteractionEnabled = false
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconContainer)
        
        let icon = UIImageView(image: UIImage(systemName: isPinEnabled ? "lock" : "lock.open"))
        icon.tintColor = isPinEnabled ? primaryColor : UIColor.white.withAlphaComponent(0.54)
        icon.isUserInteractionEnabled = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "PIN Protection"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)
        
        let statusLabel = OkIDLabel()
        statusLabel.text = isPinEnabled ? "Vault is protected" : "Tap to enable"
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        textStack.addArrangedSubview(statusLabel)
        
        let badge = OkIDLabel()
        badge.text = isPinEnabled ? "ON" : "OFF"
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textColor = isPinEnabled ? primaryColor : UIColor.white.withAlphaComponent(0.54)
        badge.backgroundColor = isPinEnabled ? primaryColor.withAlphaComponent(0.15) : UIColor.white.withAlphaComponent(0.1)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.isUserInteractionEnabled = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(badge)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),
            iconContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -8),
            
            badge.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            badge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 52),
            badge.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func toggleTapped() {
        onToggleTapped?()
    }
}
