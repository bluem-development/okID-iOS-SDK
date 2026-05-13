import UIKit

/// A consistently styled `UIScrollView` matching OkID SDK UI.
/// Automatically disables scrolling when content fits within the visible area.
/// Enables scrolling when keyboard or picker appears.
public final class OkIDScrollView: UIScrollView {
    
    private var isKeyboardVisible = false
    
    /// Default initializer with SDK defaults.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    /// Convenience initializer.
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive
        
        // Observe keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollingBehavior()
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        isKeyboardVisible = true
        updateScrollingBehavior()
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
        updateScrollingBehavior()
    }
    
    /// Disables scrolling when content fits within bounds, enables when content exceeds bounds or keyboard is visible.
    private func updateScrollingBehavior() {
        let contentFitsVertically = contentSize.height <= bounds.height
        let contentFitsHorizontally = contentSize.width <= bounds.width
        let contentFits = contentFitsVertically && contentFitsHorizontally
        
        // Enable scrolling if keyboard is visible OR content doesn't fit
        let shouldEnableScrolling = isKeyboardVisible || !contentFits
        
        isScrollEnabled = shouldEnableScrolling
        alwaysBounceVertical = shouldEnableScrolling
        alwaysBounceHorizontal = false
    }
}
