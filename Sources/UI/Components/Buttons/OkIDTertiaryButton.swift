import UIKit

/// Tertiary button for minimal UI presence (text-only style)
public final class OkIDTertiaryButton: OkIDButton {
    
    // MARK: - Initialization
    
    public init(
        title: String,
        titleColor: UIColor = .okidPrimary,
        icon: String? = nil
    ) {
        let iconImage = icon.flatMap { UIImage(systemName: $0) }
        super.init(config: .tertiary(
            titleColor: titleColor,
            icon: iconImage
        ))
        setTitle(title, for: .normal)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Convenience Methods
    
    /// Update text color
    public func setTitleColor(_ color: UIColor) {
        buttonConfig = .tertiary(
            titleColor: color,
            icon: buttonConfig.icon
        )
    }
    
    /// Update button icon
    public func setIcon(_ icon: UIImage?) {
        buttonConfig = .tertiary(
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
