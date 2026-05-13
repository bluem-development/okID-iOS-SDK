import UIKit

/// Custom alert controller utility for OkID SDK
/// Provides consistent styling and behaviour for all alerts throughout the SDK
public final class OkIDAlert {
    
    // MARK: - Alert Style
    
    public enum AlertStyle {
        case info
        case success
        case warning
        case error
    }
    
    // MARK: - Alert Action
    
    public struct Action {
        let title: String
        let style: UIAlertAction.Style
        let handler: (() -> Void)?
        
        public init(title: String, style: UIAlertAction.Style = .default, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
        
        // MARK: - Preset Actions
        
        public static func ok(handler: (() -> Void)? = nil) -> Action {
            return Action(title: "OK", style: .default, handler: handler)
        }
        
        public static func cancel(handler: (() -> Void)? = nil) -> Action {
            return Action(title: "Cancel", style: .cancel, handler: handler)
        }
        
        public static func confirm(title: String = "Confirm", handler: (() -> Void)? = nil) -> Action {
            return Action(title: title, style: .default, handler: handler)
        }
        
        public static func delete(handler: (() -> Void)? = nil) -> Action {
            return Action(title: "Delete", style: .destructive, handler: handler)
        }
        
        public static func tryAgain(handler: (() -> Void)? = nil) -> Action {
            return Action(title: "Try Again", style: .default, handler: handler)
        }
        
        public static func continueAction(handler: (() -> Void)? = nil) -> Action {
            return Action(title: "Continue", style: .default, handler: handler)
        }
    }
    
    // MARK: - Simple Alerts
    
    /// Show a simple alert with OK button
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - style: Alert style (affects icon if implemented)
    ///   - from: Presenting view controller
    ///   - completion: Optional completion handler
    public static func show(
        title: String,
        message: String? = nil,
        style: AlertStyle = .info,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        let actions: [Action] = [.ok(handler: completion)]
        presentCustomAlert(
            title: title,
            message: message,
            actions: actions,
            style: style,
            from: viewController
        )
    }
    
    /// Show an error alert
    /// - Parameters:
    ///   - title: Error title (defaults to "Error")
    ///   - message: Error message
    ///   - from: Presenting view controller
    ///   - completion: Optional completion handler
    public static func showError(
        title: String = "Error",
        message: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        show(
            title: title,
            message: message,
            style: .error,
            from: viewController,
            completion: completion
        )
    }
    
    /// Show a success alert
    /// - Parameters:
    ///   - title: Success title (defaults to "Success")
    ///   - message: Success message
    ///   - from: Presenting view controller
    ///   - completion: Optional completion handler
    public static func showSuccess(
        title: String = "Success",
        message: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        show(
            title: title,
            message: message,
            style: .success,
            from: viewController,
            completion: completion
        )
    }
    
    /// Show a warning alert
    /// - Parameters:
    ///   - title: Warning title (defaults to "Warning")
    ///   - message: Warning message
    ///   - from: Presenting view controller
    ///   - completion: Optional completion handler
    public static func showWarning(
        title: String = "Warning",
        message: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        show(
            title: title,
            message: message,
            style: .warning,
            from: viewController,
            completion: completion
        )
    }
    
    // MARK: - Confirmation Alerts
    
    /// Show a confirmation alert with Cancel and Confirm buttons
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - confirmTitle: Confirm button title (defaults to "Confirm")
    ///   - confirmStyle: Confirm button style (defaults to .default)
    ///   - from: Presenting view controller
    ///   - onConfirm: Action to perform when confirmed
    ///   - onCancel: Optional action to perform when cancelled
    public static func showConfirmation(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        confirmStyle: UIAlertAction.Style = .default,
        from viewController: UIViewController,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let actions: [Action] = [
            .cancel(handler: onCancel),
            Action(title: confirmTitle, style: confirmStyle, handler: onConfirm)
        ]
        
        let style: AlertStyle = confirmStyle == .destructive ? .error : .info
        presentCustomAlert(
            title: title,
            message: message,
            actions: actions,
            style: style,
            from: viewController
        )
    }
    
    /// Show a destructive confirmation alert (e.g., for delete operations)
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - destructiveTitle: Destructive button title (defaults to "Delete")
    ///   - from: Presenting view controller
    ///   - onConfirm: Action to perform when confirmed
    ///   - onCancel: Optional action to perform when cancelled
    public static func showDestructiveConfirmation(
        title: String,
        message: String? = nil,
        destructiveTitle: String = "Delete",
        from viewController: UIViewController,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        showConfirmation(
            title: title,
            message: message,
            confirmTitle: destructiveTitle,
            confirmStyle: .destructive,
            from: viewController,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    // MARK: - Custom Alerts
    
    /// Show an alert with custom actions
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - actions: Array of custom actions
    ///   - from: Presenting view controller
    ///   - style: Alert style
    public static func show(
        title: String,
        message: String? = nil,
        actions: [Action],
        from viewController: UIViewController,
        style: AlertStyle = .info
    ) {
        presentCustomAlert(
            title: title,
            message: message,
            actions: actions,
            style: style,
            from: viewController
        )
    }
    
    // MARK: - Action Sheet
    
    /// Show an action sheet with custom actions
    /// - Parameters:
    ///   - title: Action sheet title
    ///   - message: Action sheet message
    ///   - actions: Array of actions
    ///   - from: Presenting view controller
    ///   - sourceView: Optional source view for iPad popover (defaults to view controller's view)
    public static func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )
        
        alert.view.tintColor = .okidPrimary
        
        // Customize title appearance
        if let title = title {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.okidTextSecondary
            ]
            let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
            alert.setValue(attributedTitle, forKey: "attributedTitle")
        }
        
        // Customize message appearance
        if let message = message {
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.okidTextSecondary
            ]
            let attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)
            alert.setValue(attributedMessage, forKey: "attributedMessage")
        }
        
        for action in actions {
            alert.addAction(UIAlertAction(
                title: action.title,
                style: action.style,
                handler: { _ in action.handler?() }
            ))
        }
        
        // Configure popover for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView ?? viewController.view
            popover.sourceRect = sourceView?.bounds ?? viewController.view.bounds
            popover.permittedArrowDirections = .any
        }
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Text Input Alert
    
    /// Show an alert with text input field
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - placeholder: Text field placeholder
    ///   - defaultText: Default text in text field
    ///   - keyboardType: Keyboard type for text field
    ///   - submitTitle: Submit button title (defaults to "Submit")
    ///   - from: Presenting view controller
    ///   - onSubmit: Action to perform with the entered text
    ///   - onCancel: Optional action to perform when cancelled
    public static func showTextInput(
        title: String,
        message: String? = nil,
        placeholder: String? = nil,
        defaultText: String? = nil,
        keyboardType: UIKeyboardType = .default,
        submitTitle: String = "Submit",
        from viewController: UIViewController,
        onSubmit: @escaping (String?) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.view.tintColor = .okidPrimary
        
        // Customize title appearance
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.okidTextPrimary
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        
        // Customize message appearance if provided
        if let message = message {
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.okidTextSecondary
            ]
            let attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)
            alert.setValue(attributedMessage, forKey: "attributedMessage")
        }
        
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = defaultText
            textField.keyboardType = keyboardType
        }
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in onCancel?() }
        ))
        
        alert.addAction(UIAlertAction(
            title: submitTitle,
            style: .default,
            handler: { _ in
                let text = alert.textFields?.first?.text
                onSubmit(text)
            }
        ))
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Private Helpers
    
    /// Present custom styled alert
    private static func presentCustomAlert(
        title: String,
        message: String?,
        actions: [Action],
        style: AlertStyle,
        from viewController: UIViewController
    ) {
        // Auto-determine style based on title and actions
        let finalStyle: AlertStyle
        let lowercasedTitle = title.lowercased()
        
        // 1. If title contains "error" or "invalid" (case-insensitive), use error icon
        if lowercasedTitle.contains("error") || lowercasedTitle.contains("invalid") {
            finalStyle = .error
        }
        // 2. If alert has one button, use info icon
        else if actions.count == 1 {
            finalStyle = .info
        }
        // 3. If alert has two buttons and one is destructive, use warning icon
        else if actions.count == 2 && actions.contains(where: { $0.style == .destructive }) {
            finalStyle = .warning
        }
        // 4. Otherwise, use the passed style
        else {
            finalStyle = style
        }
        
        let alertVC = OkIDCustomAlertViewController(
            title: title,
            message: message,
            actions: actions,
            style: finalStyle
        )
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        viewController.present(alertVC, animated: true)
    }
}

// MARK: - Custom Alert View Controller

private class OkIDCustomAlertViewController: UIViewController {
    
    private let alertTitle: String
    private let alertMessage: String?
    private let actions: [OkIDAlert.Action]
    private let alertStyle: OkIDAlert.AlertStyle
    
    private let containerView = UIView()
    private let contentStackView = UIStackView()
    private let buttonsStackView = UIStackView()
    
    init(title: String, message: String?, actions: [OkIDAlert.Action], style: OkIDAlert.AlertStyle) {
        self.alertTitle = title
        self.alertMessage = message
        self.actions = actions
        self.alertStyle = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Background overlay
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Container view
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 14
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOpacity = 0.3
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Icon (based on alert style) - positioned halfway outside the alert border
        let (iconName, iconColor) = getIconForStyle(alertStyle)
        
        // Create white background circle (slightly larger to act as border)
        let whiteBackgroundCircle = UIView()
        whiteBackgroundCircle.backgroundColor = .white
        whiteBackgroundCircle.layer.cornerRadius = 36 // Larger radius
        whiteBackgroundCircle.layer.shadowColor = UIColor.black.cgColor
        whiteBackgroundCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
        whiteBackgroundCircle.layer.shadowRadius = 8
        whiteBackgroundCircle.layer.shadowOpacity = 0.2
        
        // Create shadow path for top half only
        let shadowPath = UIBezierPath()
        shadowPath.move(to: CGPoint(x: 0, y: 36)) // Left center
        shadowPath.addArc(
            withCenter: CGPoint(x: 36, y: 36),
            radius: 36,
            startAngle: .pi, // Left (180°)
            endAngle: 0, // Right (0°)
            clockwise: true // Top arc
        )
        shadowPath.addLine(to: CGPoint(x: 72, y: 36)) // Right center
        shadowPath.close()
        whiteBackgroundCircle.layer.shadowPath = shadowPath.cgPath
        
        whiteBackgroundCircle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(whiteBackgroundCircle)
        
        // Create icon container with colored background (no border)
        let iconContainer = UIView()
        iconContainer.backgroundColor = iconColor
        iconContainer.layer.cornerRadius = 32
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconContainer)
        
        let iconImageView = UIImageView(image: UIImage(systemName: iconName))
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        
        // Title label
        let titleLabel = OkIDLabel()
        titleLabel.text = alertTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .okidTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(titleLabel)
        
        // Message label
        if let message = alertMessage {
            let messageLabel = OkIDLabel()
            messageLabel.text = message
            messageLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            messageLabel.textColor = .okidTextSecondary
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            contentStackView.addArrangedSubview(messageLabel)
        }
        
        // Buttons stack view
        buttonsStackView.axis = actions.count <= 2 ? .horizontal : .vertical
        buttonsStackView.spacing = 12
        buttonsStackView.distribution = actions.count == 1 ? .fill : (actions.count <= 2 ? .fillEqually : .fill)
        buttonsStackView.alignment = actions.count == 1 ? .center : .fill
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonsStackView)
        
        // Create buttons
        for (index, action) in actions.enumerated() {
            let button = createButton(for: action, index: index, isSingleButton: actions.count == 1)
            buttonsStackView.addArrangedSubview(button)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 340),
            
            // White background circle - centered horizontally, positioned halfway outside top border
            whiteBackgroundCircle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            whiteBackgroundCircle.centerYAnchor.constraint(equalTo: containerView.topAnchor),
            whiteBackgroundCircle.widthAnchor.constraint(equalToConstant: 72),
            whiteBackgroundCircle.heightAnchor.constraint(equalToConstant: 72),
            
            // Icon container - centered on white background
            iconContainer.centerXAnchor.constraint(equalTo: whiteBackgroundCircle.centerXAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: whiteBackgroundCircle.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 64),
            iconContainer.heightAnchor.constraint(equalToConstant: 64),
            
            // Icon image inside container
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),
            
            // Content with extra top padding for icon (half of white circle height = 36pt + padding)
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 56),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            buttonsStackView.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 35),
            buttonsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Add tap gesture to dismiss on background tap (optional)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func createButton(for action: OkIDAlert.Action, index: Int, isSingleButton: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: action.style == .cancel ? .regular : .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.6
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.baselineAdjustment = .alignCenters
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        // Add padding to buttons
        if isSingleButton {
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        }
        
        // Style based on action type
        switch action.style {
        case .cancel:
            // Cancel button: white background with border
            button.backgroundColor = .white
            button.setTitleColor(.okidPrimary, for: .normal)
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor.okidPrimary.cgColor
            
        case .destructive:
            // Destructive button: error color background
            button.backgroundColor = .okidError
            button.setTitleColor(.white, for: .normal)
            
        case .default:
            // Default button: primary color background
            button.backgroundColor = .okidPrimary
            button.setTitleColor(.white, for: .normal)
        @unknown default:
            button.backgroundColor = .okidPrimary
            button.setTitleColor(.white, for: .normal)
        }
        
        // Height constraint
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    private func getIconForStyle(_ style: OkIDAlert.AlertStyle) -> (iconName: String, color: UIColor) {
        switch style {
        case .error:
            return ("xmark.circle.fill", .okidError)
        case .success:
            return ("checkmark.circle.fill", .okidSuccess)
        case .warning:
            return ("exclamationmark.triangle.fill", .okidError)
        case .info:
            return ("info.circle.fill", .okidPrimary)
        }
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let action = actions[sender.tag]
        dismiss(animated: true) {
            action.handler?()
        }
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            // Find cancel action if exists
            if let cancelAction = actions.first(where: { $0.style == .cancel }) {
                dismiss(animated: true) {
                    cancelAction.handler?()
                }
            }
        }
    }
}

// MARK: - UIViewController Extension

public extension UIViewController {
    
    /// Show a simple alert
    func showAlert(
        title: String,
        message: String? = nil,
        style: OkIDAlert.AlertStyle = .info,
        completion: (() -> Void)? = nil
    ) {
        OkIDAlert.show(
            title: title,
            message: message,
            style: style,
            from: self,
            completion: completion
        )
    }
    
    /// Show an error alert
    func showError(
        _ message: String,
        title: String = "Error",
        completion: (() -> Void)? = nil
    ) {
        OkIDAlert.showError(
            title: title,
            message: message,
            from: self,
            completion: completion
        )
    }
    
    /// Show a success alert
    func showSuccess(
        _ message: String,
        title: String = "Success",
        completion: (() -> Void)? = nil
    ) {
        OkIDAlert.showSuccess(
            title: title,
            message: message,
            from: self,
            completion: completion
        )
    }
    
    /// Show a warning alert
    func showWarning(
        _ message: String,
        title: String = "Warning",
        completion: (() -> Void)? = nil
    ) {
        OkIDAlert.showWarning(
            title: title,
            message: message,
            from: self,
            completion: completion
        )
    }
    
    /// Show a confirmation alert
    func showConfirmation(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        OkIDAlert.showConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            confirmStyle: confirmStyle,
            from: self,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    /// Show a destructive confirmation alert
    func showDestructiveConfirmation(
        title: String,
        message: String? = nil,
        destructiveTitle: String = "Delete",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        OkIDAlert.showDestructiveConfirmation(
            title: title,
            message: message,
            destructiveTitle: destructiveTitle,
            from: self,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    /// Show an action sheet
    func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [OkIDAlert.Action],
        sourceView: UIView? = nil
    ) {
        OkIDAlert.showActionSheet(
            title: title,
            message: message,
            actions: actions,
            from: self,
            sourceView: sourceView
        )
    }
}
