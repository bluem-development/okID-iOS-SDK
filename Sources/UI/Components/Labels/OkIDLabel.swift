import UIKit

/// A consistently styled `UILabel` matching OkID SDK UI.
public final class OkIDLabel: UILabel {
    
    public enum Style {
        case title
        case sectionTitle
        case body
        case caption
        case fieldLabel
    }
    
    private var theme: OkIDThemeConfig = .defaultTheme
    private var style: Style = .body
    
    /// Default initializer (`.body` + `.defaultTheme`).
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    /// Convenience initializer (`.body` + `.defaultTheme`).
    public convenience init() {
        self.init(theme: .defaultTheme, style: .body)
    }
    
    public convenience init(theme: OkIDThemeConfig = .defaultTheme, style: Style = .body) {
        self.init(frame: .zero)
        self.theme = theme
        self.style = style
        applyStyle()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        numberOfLines = 0
        adjustsFontForContentSizeCategory = true
        applyStyle()
    }
    
    private func applyStyle() {
        switch style {
        case .title:
            font = .systemFont(ofSize: 22, weight: .bold)
            textColor = theme.colors.text
            
        case .sectionTitle:
            font = .systemFont(ofSize: 18, weight: .semibold)
            textColor = theme.colors.text
            
        case .body:
            font = .systemFont(ofSize: 16, weight: .regular)
            textColor = theme.colors.text
            
        case .caption:
            font = .systemFont(ofSize: 13, weight: .regular)
            textColor = theme.colors.textSecondary
            
        case .fieldLabel:
            font = .systemFont(ofSize: 14, weight: .medium)
            textColor = .okidGray600
            numberOfLines = 1
        }
    }
}

