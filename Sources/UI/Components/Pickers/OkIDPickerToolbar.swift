import UIKit

/// Custom toolbar bar for picker input views.
/// Designed to be embedded inside `OkIDPickerInputView` (not as a standalone
/// `inputAccessoryView`) to avoid the gap iOS 26+ inserts between
/// the accessory view and the input view.
public final class OkIDPickerToolbar: UIView {
    
    public enum Style {
        case doneRight
        case closeLeft
    }
    
    static let height: CGFloat = 44
    
    public init(
        theme: OkIDThemeConfig,
        style: Style = .doneRight,
        target: Any?,
        action: Selector
    ) {
        super.init(frame: CGRect(
            x: 0, y: 0,
            width: UIScreen.main.bounds.width,
            height: OkIDPickerToolbar.height
        ))
        
        backgroundColor = theme.colors.primary
        autoresizingMask = .flexibleWidth
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        addSubview(button)
        
        switch style {
        case .closeLeft:
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44),
            ])
            
        case .doneRight:
            button.setTitle("Done", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
            
            NSLayoutConstraint.activate([
                button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
                button.heightAnchor.constraint(equalToConstant: 44),
            ])
        }
        
        button.addTarget(target, action: action, for: .touchUpInside)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// Wraps a toolbar + picker into a single UIView to be used as `textField.inputView`.
/// This eliminates the gap iOS 26 inserts between `inputAccessoryView` and `inputView`.
public final class OkIDPickerInputView: UIView {
    
    private let toolbar: OkIDPickerToolbar
    private let picker: UIView
    private static let pickerHeight: CGFloat = 216
    
    public init(
        theme: OkIDThemeConfig,
        toolbarStyle: OkIDPickerToolbar.Style = .closeLeft,
        picker: UIView,
        target: Any?,
        action: Selector
    ) {
        self.toolbar = OkIDPickerToolbar(
            theme: theme,
            style: toolbarStyle,
            target: target,
            action: action
        )
        self.picker = picker
        
        let totalHeight = OkIDPickerToolbar.height + OkIDPickerInputView.pickerHeight
        super.init(frame: CGRect(
            x: 0, y: 0,
            width: UIScreen.main.bounds.width,
            height: totalHeight
        ))
        
        autoresizingMask = .flexibleWidth
        
        toolbar.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width,
            height: OkIDPickerToolbar.height
        )
        toolbar.autoresizingMask = .flexibleWidth
        addSubview(toolbar)
        
        picker.frame = CGRect(
            x: 0, y: OkIDPickerToolbar.height,
            width: bounds.width,
            height: OkIDPickerInputView.pickerHeight
        )
        picker.autoresizingMask = [.flexibleWidth]
        addSubview(picker)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: OkIDPickerToolbar.height + OkIDPickerInputView.pickerHeight
        )
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        toolbar.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width,
            height: OkIDPickerToolbar.height
        )
        picker.frame = CGRect(
            x: 0, y: OkIDPickerToolbar.height,
            width: bounds.width,
            height: bounds.height - OkIDPickerToolbar.height
        )
    }
}
