import UIKit

/// A consistently styled `UITextField` matching OkID SDK UI.
///
/// - Rounded corners
/// - Left icon with padding
/// - Placeholder tint
/// - Focus border highlight (primary)
public final class OkIDTextField: UITextField {
    
    private let theme: OkIDThemeConfig
    private var iconImageView: UIImageView?
    private var rightPaddingView: UIView?
    
    /// Normal border color (unfocused).
    public var normalBorderColor: UIColor = .okidGray400 {
        didSet { updateBorderForCurrentState() }
    }
    
    /// Focus border color (editing).
    public var focusedBorderColor: UIColor {
        theme.colors.primary
    }
    
    public init(theme: OkIDThemeConfig, iconSystemName: String? = nil) {
        self.theme = theme
        super.init(frame: .zero)
        commonInit()
        setIcon(systemName: iconSystemName)
    }
    
    public required init?(coder: NSCoder) {
        self.theme = .defaultTheme
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        borderStyle = .none
        backgroundColor = .white
        textColor = theme.colors.text
        font = .systemFont(ofSize: 16)
        clearButtonMode = .whileEditing
        autocorrectionType = .no
        
        layer.cornerRadius = theme.borderRadius.lg
        layer.borderWidth = 1
        layer.borderColor = normalBorderColor.cgColor
        
        // Right padding
        setRightPaddingWidth(12)
        rightViewMode = .always
        
        addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        
        applyPlaceholderStyle()
    }
    
    public override var placeholder: String? {
        didSet { applyPlaceholderStyle() }
    }
    
    /// Sets/updates the left icon.
    public func setIcon(systemName: String?) {
        guard let systemName else {
            leftView = nil
            leftViewMode = .never
            iconImageView = nil
            return
        }
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 50))
        let iconView = UIImageView(image: UIImage(systemName: systemName))
        iconView.tintColor = .okidGray600
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 12, y: 15, width: 20, height: 20)
        leftPaddingView.addSubview(iconView)
        
        leftView = leftPaddingView
        leftViewMode = .always
        iconImageView = iconView
    }
    
    /// Adjust right padding (useful when overlaying trailing buttons).
    public func setRightPaddingWidth(_ width: CGFloat, height: CGFloat = 50) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        rightPaddingView = view
        rightView = view
        rightViewMode = .always
    }
    
    private func applyPlaceholderStyle() {
        guard let placeholder, !placeholder.isEmpty else { return }
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.okidGray500]
        )
    }
    
    @objc private func editingDidBegin() {
        updateBorderForCurrentState()
    }
    
    @objc private func editingDidEnd() {
        updateBorderForCurrentState()
    }
    
    private func updateBorderForCurrentState() {
        layer.borderColor = (isFirstResponder ? focusedBorderColor : normalBorderColor).cgColor
    }
}

