import UIKit

// MARK: - Field Indicator View

/// Individual field status indicator (checkmark, hourglass, or empty circle)
class FieldIndicatorView: UIView {
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let label: OkIDLabel = {
        let label = OkIDLabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }()
    
    init(label text: String) {
        super.init(frame: .zero)
        
        label.text = text
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconView)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        updateStatus(.missing)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateStatus(_ status: MrzFieldStatus) {
        switch status {
        case .validated:
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .green
        case .pending:
            iconView.image = UIImage(systemName: "hourglass")
            iconView.tintColor = .orange
        case .missing:
            iconView.image = UIImage(systemName: "circle")
            iconView.tintColor = .gray
        }
    }
}

// MARK: - MRZ Camera Overlay View

/// Pure UI overlay for the MRZ camera screen
/// Contains: top gradient, close button, status label, processing indicator,
/// guide rectangle, and field indicator status bar
class MrzCameraOverlayView: UIView {
    
    // MARK: - Callbacks
    
    var onCloseTapped: (() -> Void)?
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    
    // MARK: - UI Elements
    
    private let topOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var closeButton: OkIDButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let icon = UIImage(systemName: "xmark", withConfiguration: config)
        let buttonConfig = OkIDButtonConfig(
            backgroundColor: .clear,
            titleColor: .white,
            icon: icon,
            height: 44
        )
        let button = OkIDButton(config: buttonConfig)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let processingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let statusLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let guideRectangle: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let guideLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.text = "MRZ Area"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let docIndicator = FieldIndicatorView(label: "Doc Number")
    private let dobIndicator = FieldIndicatorView(label: "DOB")
    private let expiryIndicator = FieldIndicatorView(label: "Expiry")
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        self.primaryColor = primaryColor
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Top gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.7).cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        topOverlay.layer.addSublayer(gradient)
        
        addSubview(topOverlay)
        addSubview(closeButton)
        addSubview(processingIndicator)
        addSubview(statusLabel)
        addSubview(guideRectangle)
        guideRectangle.addSubview(guideLabel)
        addSubview(statusContainer)
        
        let indicatorStack = UIStackView(arrangedSubviews: [docIndicator, dobIndicator, expiryIndicator])
        indicatorStack.axis = .horizontal
        indicatorStack.distribution = .fillEqually
        indicatorStack.spacing = 0
        indicatorStack.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.addSubview(indicatorStack)
        
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Top overlay
            topOverlay.topAnchor.constraint(equalTo: topAnchor),
            topOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            topOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            topOverlay.heightAnchor.constraint(equalToConstant: 150),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Processing indicator
            processingIndicator.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            processingIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            // Guide rectangle
            guideRectangle.bottomAnchor.constraint(equalTo: statusContainer.topAnchor, constant: -20),
            guideRectangle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            guideRectangle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            guideRectangle.heightAnchor.constraint(equalToConstant: 120),
            
            // Guide label
            guideLabel.centerXAnchor.constraint(equalTo: guideRectangle.centerXAnchor),
            guideLabel.centerYAnchor.constraint(equalTo: guideRectangle.centerYAnchor),
            
            // Status container
            statusContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statusContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statusContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statusContainer.heightAnchor.constraint(equalToConstant: 80),
            
            // Indicator stack
            indicatorStack.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 12),
            indicatorStack.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 12),
            indicatorStack.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -12),
            indicatorStack.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: -12),
        ])
        
        // Initial guide colors
        updateGuideColor(allValidated: false)
    }
    
    // MARK: - Public Updates
    
    /// Update the status message text
    func setStatusMessage(_ message: String) {
        statusLabel.text = message
    }
    
    /// Update field indicator statuses
    func updateFieldStatuses(
        docNumber: MrzFieldStatus,
        dateOfBirth: MrzFieldStatus,
        dateOfExpiry: MrzFieldStatus
    ) {
        docIndicator.updateStatus(docNumber)
        dobIndicator.updateStatus(dateOfBirth)
        expiryIndicator.updateStatus(dateOfExpiry)
    }
    
    /// Update guide rectangle border color based on validation state
    func updateGuideColor(allValidated: Bool) {
        let color = allValidated ? UIColor.green : primaryColor
        guideRectangle.layer.borderColor = color.cgColor
        guideLabel.textColor = color
    }
    
    /// Show or hide the processing spinner
    func setProcessing(_ isProcessing: Bool) {
        if isProcessing {
            processingIndicator.startAnimating()
        } else {
            processingIndicator.stopAnimating()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame when layout changes
        if let gradient = topOverlay.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = topOverlay.bounds
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleCloseTapped() {
        onCloseTapped?()
    }
}
