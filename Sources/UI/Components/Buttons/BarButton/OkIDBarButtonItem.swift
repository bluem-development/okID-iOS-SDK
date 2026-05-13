import UIKit

/// Factory for creating consistently styled UIBarButtonItems for the OkID SDK
public final class OkIDBarButtonItem {
    
    // MARK: - Common Bar Button Items
    
    /// Creates a close button (xmark icon) with white tint
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func close(
        target: Any?,
        action: Selector,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
    
    /// Creates a back button (chevron.left icon) with white tint
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func back(
        target: Any?,
        action: Selector,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
    
    /// Creates a delete button (trash icon) with custom tint
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func delete(
        target: Any?,
        action: Selector,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
    
    /// Creates a torch/flashlight button
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The action selector
    ///   - isOn: Whether the torch is currently on
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func torch(
        target: Any?,
        action: Selector,
        isOn: Bool = false,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let iconName = isOn ? "flashlight.on.fill" : "flashlight.off.fill"
        let button = UIBarButtonItem(
            image: UIImage(systemName: iconName),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
    
    /// Creates a done button (system style)
    /// - Parameters:
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color
    /// - Returns: Configured UIBarButtonItem
    public static func done(
        target: Any?,
        action: Selector,
        tintColor: UIColor? = nil
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: target,
            action: action
        )
        if let tintColor = tintColor {
            button.tintColor = tintColor
        }
        return button
    }
    
    /// Creates a flexible space bar button item
    /// - Returns: Flexible space UIBarButtonItem
    public static func flexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
    }
    
    /// Creates a fixed space bar button item
    /// - Parameter width: The width of the fixed space
    /// - Returns: Fixed space UIBarButtonItem
    public static func fixedSpace(width: CGFloat) -> UIBarButtonItem {
        let space = UIBarButtonItem(
            barButtonSystemItem: .fixedSpace,
            target: nil,
            action: nil
        )
        space.width = width
        return space
    }
    
    // MARK: - Custom Icon Bar Button
    
    /// Creates a custom bar button with specified icon
    /// - Parameters:
    ///   - iconName: SF Symbol name
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func custom(
        icon iconName: String,
        target: Any?,
        action: Selector,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: iconName),
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
    
    /// Creates a custom bar button with text title
    /// - Parameters:
    ///   - title: The button title
    ///   - target: The target object
    ///   - action: The action selector
    ///   - tintColor: Optional custom tint color (defaults to white)
    /// - Returns: Configured UIBarButtonItem
    public static func custom(
        title: String,
        target: Any?,
        action: Selector,
        tintColor: UIColor = .white
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            title: title,
            style: .plain,
            target: target,
            action: action
        )
        button.tintColor = tintColor
        return button
    }
}
