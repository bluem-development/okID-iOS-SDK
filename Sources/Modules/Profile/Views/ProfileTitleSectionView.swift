import UIKit

/// Title section for the Profile Dashboard — shield icon + "Identity Vault" header
/// Extracted from ProfileDashboardContentView following MVC pattern
class ProfileTitleSectionView: UIView {
    
    // MARK: - Initialization
    
    init(data: ProfileTitleSectionData) {
        super.init(frame: .zero)
        buildUI(primaryColor: data.primaryColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private func buildUI(primaryColor: UIColor) {
        let iconContainer = UIView()
        iconContainer.layer.cornerRadius = 14
        iconContainer.clipsToBounds = true
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let gradientView = GradientView(colors: [
            primaryColor,
            primaryColor.withAlphaComponent(0.7)
        ])
        gradientView.layer.cornerRadius = 14
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(gradientView)
        
        let icon = UIImageView(image: UIImage(systemName: "shield"))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "Identity Vault"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        textStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = OkIDLabel()
        subtitleLabel.text = "Pre-capture for instant verification"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        textStack.addArrangedSubview(subtitleLabel)
        
        addSubview(iconContainer)
        addSubview(textStack)
        
        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: topAnchor),
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 52),
            iconContainer.heightAnchor.constraint(equalToConstant: 52),
            iconContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            
            gradientView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
