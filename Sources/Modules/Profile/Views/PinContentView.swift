import UIKit

/// PIN entry content view — all UI for the PIN screen
/// Extracted from PinViewController following MVC pattern
class PinContentView: UIView {
    
    // MARK: - Callbacks
    
    var onDigitTapped: ((String) -> Void)?
    var onBackspaceTapped: (() -> Void)?
    var onForgotPinTapped: (() -> Void)?
    
    // MARK: - Properties
    
    static let pinLength = 4
    private let primaryColor: UIColor
    private let showForgotButton: Bool
    
    // MARK: - UI Components
    
    let subtitleLabel = OkIDLabel()
    private let pinDotsStackView = UIStackView()
    let errorLabel = OkIDLabel()
    private let numpadStackView = UIStackView()
    let forgotPinButton = OkIDTertiaryButton(title: "Forgot PIN?", icon: nil)
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor, showForgotButton: Bool) {
        self.primaryColor = primaryColor
        self.showForgotButton = showForgotButton
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        
        // Subtitle
        subtitleLabel.textColor = .gray
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // PIN dots
        setupPinDots()
        addSubview(pinDotsStackView)
        pinDotsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Error label
        errorLabel.textColor = .red
        errorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        errorLabel.textAlignment = .center
        errorLabel.alpha = 0
        addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Numpad
        setupNumpad()
        addSubview(numpadStackView)
        numpadStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Forgot PIN button
        if showForgotButton {
            forgotPinButton.addTarget(self, action: #selector(forgotPinAction), for: .touchUpInside)
            addSubview(forgotPinButton)
            forgotPinButton.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 48),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            pinDotsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            pinDotsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pinDotsStackView.heightAnchor.constraint(equalToConstant: 20),
            
            errorLabel.topAnchor.constraint(equalTo: pinDotsStackView.bottomAnchor, constant: 16),
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            numpadStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 40),
            numpadStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48),
            numpadStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48)
        ])
        
        if showForgotButton {
            NSLayoutConstraint.activate([
                forgotPinButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                forgotPinButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -32)
            ])
        }
    }
    
    private func setupPinDots() {
        pinDotsStackView.axis = .horizontal
        pinDotsStackView.spacing = 24
        pinDotsStackView.alignment = .center
        pinDotsStackView.distribution = .fillEqually
        
        for _ in 0..<Self.pinLength {
            let dotView = UIView()
            dotView.translatesAutoresizingMaskIntoConstraints = false
            dotView.widthAnchor.constraint(equalToConstant: 20).isActive = true
            dotView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            dotView.layer.cornerRadius = 10
            dotView.layer.borderWidth = 2
            dotView.layer.borderColor = UIColor.lightGray.cgColor
            dotView.backgroundColor = .clear
            pinDotsStackView.addArrangedSubview(dotView)
        }
    }
    
    private func setupNumpad() {
        numpadStackView.axis = .vertical
        numpadStackView.spacing = 16
        numpadStackView.distribution = .fillEqually
        
        let rows = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]
        
        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 16
            rowStack.distribution = .equalSpacing
            rowStack.alignment = .center
            
            for digit in row {
                if digit.isEmpty {
                    let spacer = UIView()
                    spacer.translatesAutoresizingMaskIntoConstraints = false
                    spacer.widthAnchor.constraint(equalToConstant: 72).isActive = true
                    spacer.heightAnchor.constraint(equalToConstant: 72).isActive = true
                    rowStack.addArrangedSubview(spacer)
                } else if digit == "⌫" {
                    rowStack.addArrangedSubview(createBackspaceButton())
                } else {
                    rowStack.addArrangedSubview(createDigitButton(digit))
                }
            }
            
            numpadStackView.addArrangedSubview(rowStack)
        }
    }
    
    private func createDigitButton(_ digit: String) -> OkIDButton {
        let config = OkIDButtonConfig(
            backgroundColor: .okidButtonLight,
            titleColor: .okidButtonText,
            font: .systemFont(ofSize: 28, weight: .medium),
            cornerRadius: 36,
            height: 72
        )
        let button = OkIDButton(config: config)
        button.setTitle(digit, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 72).isActive = true
        button.addTarget(self, action: #selector(digitAction(_:)), for: .touchUpInside)
        return button
    }
    
    private func createBackspaceButton() -> OkIDButton {
        let icon = UIImage(systemName: "delete.left")
        let config = OkIDButtonConfig(
            backgroundColor: .clear,
            titleColor: .gray,
            cornerRadius: 36,
            icon: icon,
            height: 72
        )
        let button = OkIDButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 72).isActive = true
        button.addTarget(self, action: #selector(backspaceAction), for: .touchUpInside)
        return button
    }
    
    // MARK: - Public Methods
    
    /// Update PIN dot display
    func updatePinDots(filledCount: Int, isError: Bool) {
        for (index, dotView) in pinDotsStackView.arrangedSubviews.enumerated() {
            let isFilled = index < filledCount
            
            if isError {
                dotView.backgroundColor = .red
                dotView.layer.borderColor = UIColor.red.cgColor
            } else if isFilled {
                dotView.backgroundColor = primaryColor
                dotView.layer.borderColor = primaryColor.cgColor
            } else {
                dotView.backgroundColor = .clear
                dotView.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
    }
    
    /// Show error with shake animation
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.alpha = 1
        
        // Shake animation
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        pinDotsStackView.layer.add(animation, forKey: "shake")
    }
    
    /// Clear error state
    func clearError() {
        errorLabel.alpha = 0
    }
    
    // MARK: - Actions
    
    @objc private func digitAction(_ sender: OkIDButton) {
        guard let digit = sender.titleLabel?.text else { return }
        onDigitTapped?(digit)
    }
    
    @objc private func backspaceAction() {
        onBackspaceTapped?()
    }
    
    @objc private func forgotPinAction() {
        onForgotPinTapped?()
    }
}
