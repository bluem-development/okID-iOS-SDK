import UIKit

/// Secondary button for less prominent actions
public final class OkIDSecondaryButton: OkIDButton {
    
    // MARK: - Initialization
    
    public init(
        title: String,
        borderColor: UIColor = .okidPrimaryBorder,
        titleColor: UIColor = .white,
        icon: String? = nil
    ) {
        let iconImage = icon.flatMap { UIImage(systemName: $0) }
        super.init(config: .secondary(
            borderColor: borderColor,
            titleColor: titleColor,
            icon: iconImage
        ))
        setTitle(title, for: .normal)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Convenience Methods
    
    /// Update border color
    public func setBorderColor(_ color: UIColor) {
        buttonConfig = .secondary(
            borderColor: color,
            titleColor: buttonConfig.titleColor,
            icon: buttonConfig.icon
        )
    }
    
    /// Update button icon
    public func setIcon(_ icon: UIImage?) {
        buttonConfig = .secondary(
            borderColor: buttonConfig.borderColor ?? .white,
            titleColor: buttonConfig.titleColor,
            icon: icon
        )
    }
    
    /// Update button icon by system name
    public func setIcon(systemName: String?) {
        let iconImage = systemName.flatMap { UIImage(systemName: $0) }
        setIcon(iconImage)
    }
}
