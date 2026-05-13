import UIKit

// MARK: - Liveness Camera Overlay View

/// Pure UI overlay for the liveness camera screen
/// Contains: oval cutout, close button, status message, countdown display,
/// state indicator badge, and biometric display card
class LivenessCameraOverlayView: UIView {
    
    // MARK: - Callbacks
    
    var onCloseTapped: (() -> Void)?
    
    // MARK: - UI Elements
    
    private var ovalShapeLayer: CAShapeLayer?
    private var overlayLayer: CAShapeLayer?
    private var previewLayer: CALayer? // Reference to camera preview (for overlay ordering)
    
    private let messageLabel = OkIDLabel()
    
    private lazy var closeButton: OkIDButton = {
        let icon = UIImage(systemName: "xmark")
        let config = OkIDButtonConfig(
            backgroundColor: UIColor.black.withAlphaComponent(0.5),
            titleColor: .white,
            cornerRadius: 22,
            icon: icon,
            height: 44
        )
        let button = OkIDButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let countdownContainer = UIView()
    private let countdownLabel = OkIDLabel()
    private let countdownCircleBg = CAShapeLayer()
    private let progressRing = CAShapeLayer()
    private let stateIndicatorContainer = UIView()
    private let biometricDisplayContainer = UIView()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Close button
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        addSubview(closeButton)
        
        // Message label
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2
        messageLabel.text = "Position your face in the oval"
        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Countdown container
        countdownContainer.isHidden = true
        addSubview(countdownContainer)
        countdownContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Countdown label
        countdownLabel.textColor = .white
        countdownLabel.font = .systemFont(ofSize: 48, weight: .bold)
        countdownLabel.textAlignment = .center
        countdownLabel.text = "3"
        countdownLabel.shadowColor = UIColor.black.withAlphaComponent(0.45)
        countdownLabel.shadowOffset = CGSize(width: 0, height: 0)
        countdownContainer.addSubview(countdownLabel)
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // State indicator container
        addSubview(stateIndicatorContainer)
        stateIndicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Biometric display container
        addSubview(biometricDisplayContainer)
        biometricDisplayContainer.translatesAutoresizingMaskIntoConstraints = false
        biometricDisplayContainer.isHidden = true
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            messageLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            countdownContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdownContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            countdownContainer.widthAnchor.constraint(equalToConstant: 110),
            countdownContainer.heightAnchor.constraint(equalToConstant: 110),
            
            countdownLabel.centerXAnchor.constraint(equalTo: countdownContainer.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: countdownContainer.centerYAnchor),
            
            stateIndicatorContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            stateIndicatorContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            
            biometricDisplayContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            biometricDisplayContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            biometricDisplayContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
        ])
        
        setupCountdownProgressRing()
    }
    
    private func setupCountdownProgressRing() {
        let center = CGPoint(x: 55, y: 55)
        let radius: CGFloat = 50
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        
        countdownCircleBg.path = circlePath.cgPath
        countdownCircleBg.fillColor = UIColor.green.withAlphaComponent(0.95).cgColor
        countdownCircleBg.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        countdownCircleBg.lineWidth = 4
        countdownContainer.layer.insertSublayer(countdownCircleBg, at: 0)
        
        progressRing.path = circlePath.cgPath
        progressRing.strokeColor = UIColor.white.cgColor
        progressRing.fillColor = UIColor.clear.cgColor
        progressRing.lineWidth = 4
        progressRing.strokeEnd = 0
        progressRing.lineCap = .round
        countdownContainer.layer.addSublayer(progressRing)
    }
    
    // MARK: - Oval Cutout
    
    /// Update the oval cutout overlay. Call from viewDidLayoutSubviews.
    /// - Parameter cameraPreviewLayer: the preview layer to insert overlays above
    func updateOvalCutout(in bounds: CGRect, overlayColor: UIColor, above cameraPreviewLayer: CALayer?) {
        ovalShapeLayer?.removeFromSuperlayer()
        overlayLayer?.removeFromSuperlayer()
        
        // Calculate a face-proportioned oval that looks consistent across all screen sizes.
        // Width is based on screen width (70%), height uses a fixed 1.35:1 ratio (natural face shape).
        // This ensures the oval is always taller than wide (portrait oval) on every device.
        let ovalWidth = bounds.width * 0.70
        let ovalHeight = ovalWidth * 1.35
        let ovalX = (bounds.width - ovalWidth) / 2
        // Position slightly above vertical center for natural framing
        let ovalY = (bounds.height - ovalHeight) / 2 - bounds.height * 0.02
        
        let ovalRect = CGRect(x: ovalX, y: ovalY, width: ovalWidth, height: ovalHeight)
        let ovalPath = UIBezierPath(ovalIn: ovalRect)
        
        // Semi-transparent background with cutout
        let overlayPath = UIBezierPath(rect: bounds)
        overlayPath.append(ovalPath.reversing())
        
        let overlay = CAShapeLayer()
        overlay.path = overlayPath.cgPath
        overlay.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        overlay.fillRule = .evenOdd
        
        if let cameraPreviewLayer = cameraPreviewLayer {
            layer.insertSublayer(overlay, above: cameraPreviewLayer)
        } else {
            layer.insertSublayer(overlay, at: 0)
        }
        overlayLayer = overlay
        
        // Oval border
        let ovalBorder = CAShapeLayer()
        ovalBorder.path = ovalPath.cgPath
        ovalBorder.strokeColor = overlayColor.cgColor
        ovalBorder.fillColor = UIColor.clear.cgColor
        ovalBorder.lineWidth = 3
        layer.insertSublayer(ovalBorder, above: overlay)
        ovalShapeLayer = ovalBorder
    }
    
    // MARK: - Public UI Updates
    
    /// Update status message text
    func setStatusMessage(_ message: String) {
        messageLabel.text = message
    }
    
    /// Update oval border color
    func setOvalColor(_ color: UIColor) {
        ovalShapeLayer?.strokeColor = color.cgColor
    }
    
    /// Show/hide countdown container
    func setCountdownVisible(_ visible: Bool) {
        countdownContainer.isHidden = !visible
    }
    
    /// Show countdown with initial value
    func showCountdown(value: Int) {
        countdownContainer.isHidden = false
        countdownLabel.text = "\(value)"
    }
    
    /// Update countdown display with animation
    func updateCountdown(remaining: Int) {
        countdownLabel.text = "\(remaining)"
        
        // Update progress ring
        let progress = 1.0 - (CGFloat(remaining) / 3.0)
        progressRing.strokeEnd = progress
        
        // Animate countdown number
        UIView.animate(withDuration: 0.2, animations: {
            self.countdownLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.countdownLabel.transform = .identity
            }
        }
    }
    
    /// Update state indicator badge
    func updateStateIndicator(visible: Bool, info: (icon: String, color: UIColor, text: String)?) {
        stateIndicatorContainer.isHidden = !visible
        
        guard visible, let info = info else { return }
        
        stateIndicatorContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let badge = UIView()
        badge.backgroundColor = info.color.withAlphaComponent(0.9)
        badge.layer.cornerRadius = 24
        badge.layer.shadowColor = UIColor.black.cgColor
        badge.layer.shadowOpacity = 0.3
        badge.layer.shadowOffset = CGSize(width: 0, height: 2)
        badge.layer.shadowRadius = 8
        badge.translatesAutoresizingMaskIntoConstraints = false
        stateIndicatorContainer.addSubview(badge)
        
        let iconView = UIImageView(image: UIImage(systemName: info.icon))
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(iconView)
        
        let label = OkIDLabel()
        label.text = info.text
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)
        
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: stateIndicatorContainer.topAnchor),
            badge.leadingAnchor.constraint(equalTo: stateIndicatorContainer.leadingAnchor),
            badge.trailingAnchor.constraint(equalTo: stateIndicatorContainer.trailingAnchor),
            badge.bottomAnchor.constraint(equalTo: stateIndicatorContainer.bottomAnchor),
            badge.heightAnchor.constraint(equalToConstant: 48),
            
            iconView.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
        ])
    }
    
    /// Update biometric display card
    func updateBiometricDisplay(reading: AgeGenderReading?) {
        guard let reading = reading else {
            biometricDisplayContainer.isHidden = true
            return
        }
        
        biometricDisplayContainer.isHidden = false
        biometricDisplayContainer.subviews.forEach { $0.removeFromSuperview() }
        
        let age = Int(reading.age.rounded())
        let gender = reading.gender.uppercased()
        let confidence = Int(reading.confidence * 100)
        
        let card = UIView()
        card.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        biometricDisplayContainer.addSubview(card)
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let personIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        personIcon.tintColor = .white.withAlphaComponent(0.9)
        personIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let ageLabel = OkIDLabel()
        ageLabel.text = "Age: \(age)"
        ageLabel.textColor = .white.withAlphaComponent(0.9)
        ageLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let separator = UIView()
        separator.backgroundColor = .white.withAlphaComponent(0.3)
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        let genderIconName: String
        if #available(iOS 16.0, *) {
            genderIconName = gender == "MALE" ? "figure.stand" : "figure.stand.dress"
        } else {
            genderIconName = gender == "MALE" ? "person.fill" : "person.fill"
        }
        let genderIcon = UIImageView(image: UIImage(systemName: genderIconName))
        genderIcon.tintColor = .white.withAlphaComponent(0.9)
        genderIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let genderLabel = OkIDLabel()
        genderLabel.text = "\(gender) (\(confidence)%)"
        genderLabel.textColor = .white.withAlphaComponent(0.9)
        genderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        stack.addArrangedSubview(personIcon)
        stack.addArrangedSubview(ageLabel)
        stack.addArrangedSubview(separator)
        stack.addArrangedSubview(genderIcon)
        stack.addArrangedSubview(genderLabel)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: biometricDisplayContainer.topAnchor),
            card.leadingAnchor.constraint(equalTo: biometricDisplayContainer.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: biometricDisplayContainer.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: biometricDisplayContainer.bottomAnchor),
            
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func handleCloseTapped() {
        onCloseTapped?()
    }
}
