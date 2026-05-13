import UIKit

/// A picker for choosing a string value, styled to match OkID SDK theme.
public final class OkIDStringPickerView: UIPickerView {
    
    public typealias SelectionHandler = (_ selectedIndex: Int, _ selectedValue: String) -> Void
    
    public var onSelectionChanged: SelectionHandler?
    
    public var items: [String] {
        didSet {
            reloadAllComponents()
        }
    }
    
    private let theme: OkIDThemeConfig
    
    public init(items: [String], theme: OkIDThemeConfig) {
        self.items = items
        self.theme = theme
        super.init(frame: .zero)
        
        delegate = self
        dataSource = self
        backgroundColor = .white
    }
    
    public required init?(coder: NSCoder) {
        self.items = []
        self.theme = .defaultTheme
        super.init(coder: coder)
        
        delegate = self
        dataSource = self
        backgroundColor = .white
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // When picker appears, reload to ensure colors are correct
        if window != nil {
            reloadAllComponents()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Remove selection indicator overlay backgrounds
        for subview in subviews {
            if subview.bounds.height <= 1.0 {
                subview.backgroundColor = .clear
            }
        }
    }
    
    public func setSelectedValue(_ value: String?) {
        guard let value, let idx = items.firstIndex(of: value) else { return }
        selectRow(idx, inComponent: 0, animated: false)
        reloadAllComponents()
    }
}

extension OkIDStringPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        items.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        56
    }
    
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.bounds.width
    }
    
    public func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        // Create a container view to ensure proper centering
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let label = OkIDLabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 20, weight: .regular)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // All rows use primary color
        label.textColor = theme.colors.primary
        
        label.text = (row < items.count) ? items[row] : nil
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < items.count else { return }
        onSelectionChanged?(row, items[row])
    }
}
