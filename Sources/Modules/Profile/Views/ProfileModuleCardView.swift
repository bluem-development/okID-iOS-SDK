import UIKit

/// Reusable module card for the Profile Dashboard (Document, Selfie, Passport Chip)
/// Receives pre-computed display data — no manager dependency
/// Extracted from ProfileDashboardContentView following MVC pattern
class ProfileModuleCardView: UIView {
    
    // MARK: - Callbacks
    
    var onTapped: ((String) -> Void)?
    
    // MARK: - Properties
    
    private let moduleKey: String
    
    // MARK: - Initialization
    
    init(data: ProfileModuleCardData) {
        self.moduleKey = data.moduleKey
        super.init(frame: .zero)
        buildUI(data: data)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private func buildUI(data: ProfileModuleCardData) {
        // Container is a button for tap handling
        let container = UIButton(type: .custom)
        container.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = (data.isCaptured
            ? data.statusColor.withAlphaComponent(0.3)
            : UIColor.white.withAlphaComponent(0.1)
        ).cgColor
        container.addTarget(self, action: #selector(cardTapped), for: .touchUpInside)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        
        // Icon container
        let iconContainer = UIView()
        iconContainer.backgroundColor = data.isCaptured
            ? data.statusColor.withAlphaComponent(0.15)
            : UIColor.white.withAlphaComponent(0.08)
        iconContainer.layer.cornerRadius = 14
        iconContainer.isUserInteractionEnabled = false
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconContainer)
        
        let iconImage = UIImageView(image: UIImage(systemName: data.icon))
        iconImage.tintColor = data.isCaptured ? data.statusColor : UIColor.white.withAlphaComponent(0.38)
        iconImage.isUserInteractionEnabled = false
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImage)
        
        // Status indicator badge (if captured)
        if data.isCaptured, let badgeIconName = data.statusBadgeIcon {
            let badge = UIView()
            badge.backgroundColor = data.statusColor
            badge.layer.cornerRadius = 9
            badge.layer.borderWidth = 2
            badge.layer.borderColor = UIColor.okidBackgroundDark.cgColor
            badge.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(badge)
            
            let badgeIcon = UIImageView(image: UIImage(systemName: badgeIconName))
            badgeIcon.tintColor = .white
            badgeIcon.translatesAutoresizingMaskIntoConstraints = false
            badge.addSubview(badgeIcon)
            
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
                badge.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
                badge.widthAnchor.constraint(equalToConstant: 18),
                badge.heightAnchor.constraint(equalToConstant: 18),
                
                badgeIcon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
                badgeIcon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
                badgeIcon.widthAnchor.constraint(equalToConstant: 10),
                badgeIcon.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
        
        // Text content
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)
        
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center
        
        let titleLabel = OkIDLabel()
        titleLabel.text = data.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleRow.addArrangedSubview(titleLabel)
        
        if data.isOptional {
            let optionalBadge = OkIDLabel()
            optionalBadge.text = "Optional"
            optionalBadge.font = .systemFont(ofSize: 10, weight: .medium)
            optionalBadge.textColor = UIColor.white.withAlphaComponent(0.5)
            optionalBadge.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            optionalBadge.textAlignment = .center
            optionalBadge.layer.cornerRadius = 4
            optionalBadge.clipsToBounds = true
            optionalBadge.translatesAutoresizingMaskIntoConstraints = false
            optionalBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
            optionalBadge.heightAnchor.constraint(equalToConstant: 16).isActive = true
            titleRow.addArrangedSubview(optionalBadge)
        }
        
        textStack.addArrangedSubview(titleRow)
        
        if let hint = data.tierHint, !data.isCaptured {
            let hintLabel = OkIDLabel()
            hintLabel.text = hint
            hintLabel.font = .systemFont(ofSize: 11)
            hintLabel.textColor = UIColor.white.withAlphaComponent(0.4)
            textStack.addArrangedSubview(hintLabel)
        }
        
        let statusLabel = OkIDLabel()
        statusLabel.text = data.statusText
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = data.isCaptured ? data.statusColor : UIColor.white.withAlphaComponent(0.38)
        textStack.addArrangedSubview(statusLabel)
        
        // Action indicator
        let actionContainer = UIView()
        actionContainer.backgroundColor = data.isCaptured
            ? UIColor.white.withAlphaComponent(0.08)
            : data.primaryColor.withAlphaComponent(0.2)
        actionContainer.layer.cornerRadius = 8
        actionContainer.isUserInteractionEnabled = false
        actionContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(actionContainer)
        
        let actionIcon = UIImageView(image: UIImage(systemName: data.isCaptured ? "chevron.right" : "plus"))
        actionIcon.tintColor = data.isCaptured ? UIColor.white.withAlphaComponent(0.38) : data.primaryColor
        actionIcon.isUserInteractionEnabled = false
        actionIcon.translatesAutoresizingMaskIntoConstraints = false
        actionContainer.addSubview(actionIcon)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconContainer.widthAnchor.constraint(equalToConstant: 50),
            iconContainer.heightAnchor.constraint(equalToConstant: 50),
            iconContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            iconImage.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 26),
            iconImage.heightAnchor.constraint(equalToConstant: 26),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: actionContainer.leadingAnchor, constant: -8),
            
            actionContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            actionContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            actionContainer.widthAnchor.constraint(equalToConstant: 32),
            actionContainer.heightAnchor.constraint(equalToConstant: 32),
            
            actionIcon.centerXAnchor.constraint(equalTo: actionContainer.centerXAnchor),
            actionIcon.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),
            actionIcon.widthAnchor.constraint(equalToConstant: 18),
            actionIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        onTapped?(moduleKey)
    }
}
