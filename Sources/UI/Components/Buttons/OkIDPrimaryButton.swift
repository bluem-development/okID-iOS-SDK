import UIKit

/// Primary button for main actions
public final class OkIDPrimaryButton: OkIDButton {
    
    // MARK: - Initialization
    
    public init(
        title: String,
        color: UIColor = .okidPrimary,
        icon: String? = nil
    ) {
        let iconImage = icon.flatMap { UIImage(systemName: $0) }
        super.init(config: .primary(color: color, icon: iconImage))
        setTitle(title, for: .normal)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Convenience Methods
    
    /// Update button color
    public func setColor(_ color: UIColor) {
        buttonConfig = .primary(
            color: color,
            icon: buttonConfig.icon
        )
    }
    
    /// Update button icon
    public func setIcon(_ icon: UIImage?) {
        buttonConfig = .primary(
            color: buttonConfig.backgroundColor,
            icon: icon
        )
    }
    
    /// Update button icon by system name
    public func setIcon(systemName: String?) {
        let iconImage = systemName.flatMap { UIImage(systemName: $0) }
        setIcon(iconImage)
    }
}
