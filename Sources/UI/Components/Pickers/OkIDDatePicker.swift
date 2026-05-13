import UIKit

/// Consistently styled date picker for OkID SDK forms.
public final class OkIDDatePicker: UIDatePicker {
    
    private let wheelTextColor: UIColor
    
    public init(theme: OkIDThemeConfig, mode: UIDatePicker.Mode = .date) {
        self.wheelTextColor = theme.colors.primary
        super.init(frame: .zero)
        datePickerMode = mode
        
        if #available(iOS 13.4, *) {
            preferredDatePickerStyle = .wheels
        }
        
        tintColor = theme.colors.primary
        backgroundColor = theme.colors.surface

        // Wheel label text color (private API via KVC; widely used for wheel-style UIDatePicker)
        // Falls back gracefully if not supported.
        setValue(wheelTextColor, forKey: "textColor")
        
        // iOS may rebuild wheel subviews while scrolling (e.g. changing years), which can reset label colors.
        // Re-apply on value changes as a best-effort fix.
        addTarget(self, action: #selector(reapplyWheelTextStyling), for: .valueChanged)
        reapplyWheelTextStyling()
    }
    
    public required init?(coder: NSCoder) {
        self.wheelTextColor = .okidPrimary
        super.init(coder: coder)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        reapplyWheelTextStyling()
    }
    
    @objc private func reapplyWheelTextStyling() {
        // Best-effort, may not be supported on all OS versions.
        setValue(wheelTextColor, forKey: "textColor")
        
        // Also recolor any wheel labels that are created/recycled dynamically.
        applyLabelColorRecursively(in: self, color: wheelTextColor)
    }
    
    private func applyLabelColorRecursively(in view: UIView, color: UIColor) {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                label.textColor = color
                if let attributed = label.attributedText, attributed.length > 0 {
                    let mutable = NSMutableAttributedString(attributedString: attributed)
                    mutable.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutable.length))
                    label.attributedText = mutable
                }
            }
            applyLabelColorRecursively(in: subview, color: color)
        }
    }
}

