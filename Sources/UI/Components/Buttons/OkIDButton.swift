import UIKit

/// Base button class for OkID SDK buttons
open class OkIDButton: UIButton {
    
    // MARK: - Properties
    
    /// Button configuration
    public var buttonConfig: OkIDButtonConfig {
        didSet {
            updateAppearance()
        }
    }
    
    /// Loading state
    public var isLoading: Bool = false {
        didSet {
            updateLoadingState()
        }
    }
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var originalTitle: String?
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    public init(config: OkIDButtonConfig) {
        self.buttonConfig = config
        super.init(frame: .zero)
        setupButton()
    }
    
    public required init?(coder: NSCoder) {
        self.buttonConfig = .primary()
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Add activity indicator
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Apply initial appearance
        updateAppearance()
        
        // Add touch effects
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func updateAppearance() {
        // Background
        backgroundColor = buttonConfig.backgroundColor
        
        // Title
        setTitleColor(buttonConfig.titleColor, for: .normal)
        setTitleColor(buttonConfig.titleColor.withAlphaComponent(0.6), for: .disabled)
        titleLabel?.font = buttonConfig.font
        
        // Border
        layer.cornerRadius = buttonConfig.cornerRadius
        layer.borderWidth = buttonConfig.borderWidth
        layer.borderColor = buttonConfig.borderColor?.cgColor
        
        // Shadow
        if buttonConfig.hasShadow {
            layer.shadowColor = buttonConfig.backgroundColor.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowOpacity = 0.3
            layer.shadowRadius = 6
        } else {
            layer.shadowOpacity = 0
        }
        
        // Icon
        if let icon = buttonConfig.icon {
            var config = UIButton.Configuration.plain()
            config.image = icon
            config.baseForegroundColor = buttonConfig.titleColor
            config.imagePadding = 10
            config.imagePlacement = buttonConfig.iconPlacement
            configuration = config
        }
        
        // Height constraint — reuse a single constraint to avoid conflicts
        if let height = buttonConfig.height {
            if let existing = heightConstraint {
                existing.constant = height
            } else {
                let c = heightAnchor.constraint(equalToConstant: height)
                c.isActive = true
                heightConstraint = c
            }
        } else {
            heightConstraint?.isActive = false
            heightConstraint = nil
        }
    }
    
    private func updateLoadingState() {
        if isLoading {
            originalTitle = title(for: .normal)
            setTitle("", for: .normal)
            activityIndicator.color = buttonConfig.titleColor
            activityIndicator.startAnimating()
            isEnabled = false
            imageView?.alpha = 0
        } else {
            setTitle(originalTitle, for: .normal)
            activityIndicator.stopAnimating()
            isEnabled = true
            imageView?.alpha = 1
        }
    }
    
    // MARK: - Touch Effects
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.alpha = 0.8
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}

// MARK: - Button Configuration

public struct OkIDButtonConfig {
    public let backgroundColor: UIColor
    public let titleColor: UIColor
    public let font: UIFont
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let borderColor: UIColor?
    public let hasShadow: Bool
    public let icon: UIImage?
    public let iconPlacement: NSDirectionalRectEdge
    public let height: CGFloat?
    
    public init(
        backgroundColor: UIColor,
        titleColor: UIColor,
        font: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold),
        cornerRadius: CGFloat = 14,
        borderWidth: CGFloat = 0,
        borderColor: UIColor? = nil,
        hasShadow: Bool = false,
        icon: UIImage? = nil,
        iconPlacement: NSDirectionalRectEdge = .leading,
        height: CGFloat? = 56
    ) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.font = font
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.hasShadow = hasShadow
        self.icon = icon
        self.iconPlacement = iconPlacement
        self.height = height
    }
    
    // MARK: - Presets
    
    /// Primary button configuration (solid background with shadow)
    public static func primary(
        color: UIColor = .okidPrimary,
        icon: UIImage? = nil
    ) -> OkIDButtonConfig {
        return OkIDButtonConfig(
            backgroundColor: color,
            titleColor: .white,
            hasShadow: true,
            icon: icon
        )
    }
    
    /// Secondary button configuration (outlined with border)
    public static func secondary(
        borderColor: UIColor = .okidPrimaryBorder,
        titleColor: UIColor = .white,
        icon: UIImage? = nil
    ) -> OkIDButtonConfig {
        // Use transparent background when titleColor is not white (for light backgrounds)
        let backgroundColor = (titleColor == .white) ? UIColor.white.withAlphaComponent(0.12) : .clear
        return OkIDButtonConfig(
            backgroundColor: backgroundColor,
            titleColor: titleColor,
            borderWidth: 1.5,
            borderColor: borderColor,
            icon: icon
        )
    }
    
    /// Tertiary button configuration (minimal, no border)
    public static func tertiary(
        titleColor: UIColor = .okidPrimary,
        icon: UIImage? = nil
    ) -> OkIDButtonConfig {
        return OkIDButtonConfig(
            backgroundColor: .clear,
            titleColor: titleColor,
            icon: icon,
            height: nil
        )
    }
}
