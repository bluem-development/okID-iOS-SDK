import UIKit

// MARK: - QR Scanner Overlay View

/// Overlay UI for the QR scanner camera view
/// Handles icon, instruction labels, scan frame, and dark overlay
/// Communicates back to controller via callbacks
class QRScannerOverlayView: UIView {
    
    // MARK: - UI Components
    
    private let iconImageView = UIImageView()
    private let instructionLabel = OkIDLabel()
    private let subtitleLabel = OkIDLabel()
    private let scanFrameView = UIView()
    private let darkOverlayLayer = CAShapeLayer()
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        self.primaryColor = primaryColor
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateDarkOverlay()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        // Icon
        iconImageView.image = UIImage(systemName: "qrcode.viewfinder")
        iconImageView.tintColor = primaryColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        // Instruction label
        instructionLabel.text = "Point your camera at the QR code"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        
        // Subtitle label
        subtitleLabel.text = "The QR code is displayed on your computer screen"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        // Scan frame overlay
        scanFrameView.backgroundColor = .clear
        scanFrameView.layer.borderWidth = 2
        scanFrameView.layer.borderColor = primaryColor.cgColor
        scanFrameView.layer.cornerRadius = 12
        scanFrameView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scanFrameView)
        
        // Dark overlay with cutout
        darkOverlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        darkOverlayLayer.fillRule = .evenOdd
        layer.insertSublayer(darkOverlayLayer, at: 0)
        
        // Constraints
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: instructionLabel.topAnchor, constant: -12),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            instructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            instructionLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -8),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            
            scanFrameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -60),
            scanFrameView.widthAnchor.constraint(equalToConstant: 280),
            scanFrameView.heightAnchor.constraint(equalToConstant: 280),
        ])
    }
    
    // MARK: - Dark Overlay
    
    private func updateDarkOverlay() {
        let path = UIBezierPath(rect: bounds)
        let cutoutPath = UIBezierPath(
            roundedRect: scanFrameView.frame,
            cornerRadius: scanFrameView.layer.cornerRadius
        )
        path.append(cutoutPath)
        darkOverlayLayer.path = path.cgPath
        darkOverlayLayer.frame = bounds
    }
}
