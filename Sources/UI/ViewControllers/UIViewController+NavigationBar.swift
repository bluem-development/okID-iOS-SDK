import UIKit

/// Extension to provide generic navigation bar configuration for OkID SDK
public extension UIViewController {
    
    /// Configure navigation bar with SDK styling
    /// - Parameters:
    ///   - backgroundColor: Background color for the navigation bar (defaults to primary color)
    ///   - tintColor: Tint color for navigation bar items (defaults to white)
    ///   - titleColor: Title text color (defaults to white)
    ///   - titleFont: Title font (defaults to system font 17pt semibold)
    ///   - isTranslucent: Whether the navigation bar is translucent (defaults to false)
    func configureNavigationBar(
        backgroundColor: UIColor = .okidPrimary,
        tintColor: UIColor = .white,
        titleColor: UIColor = .white,
        titleFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold),
        isTranslucent: Bool = false
    ) {
        guard let navigationController = navigationController else { return }
        
        // Use modern UINavigationBarAppearance for iOS 13+
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: titleFont
        ]
        appearance.shadowColor = nil
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = tintColor
        navigationController.navigationBar.isTranslucent = isTranslucent
    }
}
