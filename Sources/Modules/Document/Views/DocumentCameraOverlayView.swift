import UIKit

/// Camera overlay view for document capture with guide frame and quality indicator
class DocumentCameraOverlayView: UIView {
    
    private let side: String
    private let qualityThreshold: Double
    private let onCancel: () -> Void
    
    private var qualityScore: Double?
    private var detectionState: DetectionState = .searching
    
    // UI Elements
    private let overlayLayer = CAShapeLayer()
    private let guideLayer = CAShapeLayer()
    private let cornerIndicatorsLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()
    
    private let statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let qualityBarContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let qualityBarLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.text = "Image Sharpness"
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let qualityScoreLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .bold)
        return label
    }()
    
    private let qualityBarBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let qualityBarFill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let qualityBarThresholdMarker: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let qualityBarThresholdLabel: OkIDLabel = {
        let label = OkIDLabel()
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 9)
        return label
    }()
    
    private var qualityBarFillWidthConstraint: NSLayoutConstraint?
    private var qualityBarThresholdLeadingConstraint: NSLayoutConstraint?
    
    private lazy var closeButton: OkIDButton = {
        let icon = UIImage(systemName: "xmark")
        let config = OkIDButtonConfig(
            backgroundColor: .clear,
            titleColor: .white,
            icon: icon,
            height: 44
        )
        let button = OkIDButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    init(side: String, qualityThreshold: Double, onCancel: @escaping () -> Void) {
        self.side = side
        self.qualityThreshold = qualityThreshold
        self.onCancel = onCancel
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Add status container
        addSubview(statusContainer)
        statusContainer.addSubview(statusLabel)
        statusContainer.addSubview(qualityBarContainer)
        
        // Setup quality bar
        qualityBarContainer.addSubview(qualityBarLabel)
        qualityBarContainer.addSubview(qualityScoreLabel)
        qualityBarContainer.addSubview(qualityBarBackground)
        qualityBarBackground.addSubview(qualityBarFill)
        qualityBarBackground.addSubview(qualityBarThresholdMarker)
        qualityBarContainer.addSubview(qualityBarThresholdLabel)
        
        // Add close button
        addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        // Setup constraints
        qualityBarFillWidthConstraint = qualityBarFill.widthAnchor.constraint(equalToConstant: 0)
        qualityBarThresholdLeadingConstraint = qualityBarThresholdMarker.leadingAnchor.constraint(equalTo: qualityBarBackground.leadingAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            // Close button (positioned first to reference in status container)
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Status container (avoid overlapping close button)
            statusContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            statusContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            statusContainer.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            // Status label (no bottom pin — quality bar below defines the container's bottom)
            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -16),
            
            // Quality bar container
            qualityBarContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            qualityBarContainer.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 16),
            qualityBarContainer.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -16),
            qualityBarContainer.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: -12),
            qualityBarContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // Quality bar label and score
            qualityBarLabel.topAnchor.constraint(equalTo: qualityBarContainer.topAnchor),
            qualityBarLabel.leadingAnchor.constraint(equalTo: qualityBarContainer.leadingAnchor),
            
            qualityScoreLabel.topAnchor.constraint(equalTo: qualityBarContainer.topAnchor),
            qualityScoreLabel.trailingAnchor.constraint(equalTo: qualityBarContainer.trailingAnchor),
            
            // Quality bar background
            qualityBarBackground.topAnchor.constraint(equalTo: qualityBarLabel.bottomAnchor, constant: 8),
            qualityBarBackground.leadingAnchor.constraint(equalTo: qualityBarContainer.leadingAnchor),
            qualityBarBackground.trailingAnchor.constraint(equalTo: qualityBarContainer.trailingAnchor),
            qualityBarBackground.heightAnchor.constraint(equalToConstant: 8),
            
            // Quality bar fill
            qualityBarFill.topAnchor.constraint(equalTo: qualityBarBackground.topAnchor),
            qualityBarFill.leadingAnchor.constraint(equalTo: qualityBarBackground.leadingAnchor),
            qualityBarFill.heightAnchor.constraint(equalTo: qualityBarBackground.heightAnchor),
            qualityBarFillWidthConstraint!,
            
            // Threshold marker
            qualityBarThresholdLeadingConstraint!,
            qualityBarThresholdMarker.centerYAnchor.constraint(equalTo: qualityBarBackground.centerYAnchor),
            qualityBarThresholdMarker.widthAnchor.constraint(equalToConstant: 2),
            qualityBarThresholdMarker.heightAnchor.constraint(equalToConstant: 20),
            
            // Threshold label
            qualityBarThresholdLabel.centerXAnchor.constraint(equalTo: qualityBarThresholdMarker.centerXAnchor),
            qualityBarThresholdLabel.bottomAnchor.constraint(equalTo: qualityBarBackground.topAnchor, constant: -2)
        ])
        
        // Set initial message
        statusLabel.text = "Position \(side) of document in frame"
        
        // Set threshold label
        qualityBarThresholdLabel.text = "min \(Int(qualityThreshold))"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Draw overlay with guide cutout
        drawOverlay()
    }
    
    // MARK: - Drawing
    
    private func drawOverlay() {
        // Remove old layers
        overlayLayer.removeFromSuperlayer()
        guideLayer.removeFromSuperlayer()
        cornerIndicatorsLayer.removeFromSuperlayer()
        glowLayer.removeFromSuperlayer()
        
        let guideWidth = bounds.width * 0.85
        let guideHeight = guideWidth * 0.63
        let guideX = (bounds.width - guideWidth) / 2
        let guideY = (bounds.height - guideHeight) / 2
        let guideRect = CGRect(x: guideX, y: guideY, width: guideWidth, height: guideHeight)
        
        // Draw darker semi-transparent overlay with clear cutout
        let overlayPath = UIBezierPath(rect: bounds)
        let guidePath = UIBezierPath(roundedRect: guideRect, cornerRadius: 12)
        overlayPath.append(guidePath)
        overlayPath.usesEvenOddFillRule = true
        
        overlayLayer.path = overlayPath.cgPath
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.4).cgColor
        layer.insertSublayer(overlayLayer, at: 0)
        
        // Get border color based on detection state
        let borderColor = getDynamicBorderColor()
        let borderWidth: CGFloat = getDocumentDetected() ? 4.0 : 3.0
        
        // Draw guide border
        guideLayer.path = guidePath.cgPath
        guideLayer.strokeColor = borderColor.cgColor
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.lineWidth = borderWidth
        layer.addSublayer(guideLayer)
        
        // Draw glow effect when ready
        if isReady() {
            glowLayer.path = guidePath.cgPath
            glowLayer.strokeColor = borderColor.withAlphaComponent(0.3).cgColor
            glowLayer.fillColor = UIColor.clear.cgColor
            glowLayer.lineWidth = borderWidth + 8
            glowLayer.shadowColor = borderColor.cgColor
            glowLayer.shadowRadius = 8
            glowLayer.shadowOpacity = 0.5
            glowLayer.shadowOffset = .zero
            layer.insertSublayer(glowLayer, below: guideLayer)
        }
        
        // Draw corner indicators
        drawCornerIndicators(in: guideRect, borderColor: borderColor, borderWidth: borderWidth + 1)
    }
    
    private func drawCornerIndicators(in rect: CGRect, borderColor: UIColor, borderWidth: CGFloat) {
        let cornerPath = UIBezierPath()
        let cornerLength: CGFloat = 35.0
        
        // Top-left
        cornerPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
        cornerPath.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))
        cornerPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
        cornerPath.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        
        // Top-right
        cornerPath.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        cornerPath.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        cornerPath.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        cornerPath.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))
        
        // Bottom-left
        cornerPath.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        cornerPath.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        cornerPath.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        cornerPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
        
        // Bottom-right
        cornerPath.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        cornerPath.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))
        cornerPath.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        cornerPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        
        cornerIndicatorsLayer.path = cornerPath.cgPath
        cornerIndicatorsLayer.strokeColor = borderColor.cgColor
        cornerIndicatorsLayer.fillColor = UIColor.clear.cgColor
        cornerIndicatorsLayer.lineWidth = borderWidth
        cornerIndicatorsLayer.lineCap = .round
        layer.addSublayer(cornerIndicatorsLayer)
    }
    
    // MARK: - Public Methods
    
    func update(qualityScore: Double?, detectionState: DetectionState, message: String) {
        self.qualityScore = qualityScore
        self.detectionState = detectionState
        
        statusLabel.text = message
        
        // Show/hide quality bar based on detection state
        let documentDetected = getDocumentDetected()
        qualityBarContainer.isHidden = !documentDetected
        
        if documentDetected, let score = qualityScore {
            updateQualityBar(score: score)
        }
        
        // Redraw overlay with new colors
        setNeedsLayout()
    }
    
    // MARK: - Helper Methods
    
    private func getDynamicBorderColor() -> UIColor {
        guard let score = qualityScore else {
            return .white
        }
        
        let documentDetected = getDocumentDetected()
        let meetsQuality = score >= qualityThreshold
        
        if documentDetected && meetsQuality {
            return .okidSuccess // Green - ready
        } else if documentDetected {
            return .okidWarningYellow // Yellow - detected but needs adjustment
        }
        
        return .white // Default/searching
    }
    
    private func getDocumentDetected() -> Bool {
        return detectionState == .ready || detectionState == .detectedBlurry
    }
    
    private func isReady() -> Bool {
        guard let score = qualityScore else {
            return false
        }
        return getDocumentDetected() && score >= qualityThreshold
    }
    
    private func updateQualityBar(score: Double) {
        let maxScore: Double = 10.0
        let clampedScore = min(max(score, 0), maxScore)
        let clampedThreshold = min(max(qualityThreshold, 0), maxScore)
        
        let progress = clampedScore / maxScore
        let thresholdPosition = clampedThreshold / maxScore
        let meetsThreshold = clampedScore >= clampedThreshold
        
        // Update score label
        qualityScoreLabel.text = String(format: "%.1f", clampedScore)
        qualityScoreLabel.textColor = meetsThreshold
            ? UIColor.okidSuccess // Green
            : UIColor.okidWarning // Amber
        
        // Update fill width
        layoutIfNeeded()
        let barWidth = qualityBarBackground.bounds.width
        qualityBarFillWidthConstraint?.constant = barWidth * CGFloat(progress)
        
        // Update fill gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = qualityBarFill.bounds
        
        if meetsThreshold {
            gradientLayer.colors = [
                UIColor.okidSuccess.cgColor,
                UIColor.okidSuccess.withAlphaComponent(0.8).cgColor
            ]
        } else {
            gradientLayer.colors = [
                UIColor.okidError.cgColor,
                UIColor.okidWarning.cgColor
            ]
        }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 4
        
        qualityBarFill.layer.sublayers?.removeAll()
        qualityBarFill.layer.addSublayer(gradientLayer)
        
        // Update threshold marker position
        let thresholdX = barWidth * CGFloat(thresholdPosition)
        qualityBarThresholdLeadingConstraint?.constant = thresholdX - 1
        
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func closeTapped() {
        onCancel()
    }
}

