import UIKit

/// Content view for document preview — all UI elements
/// Extracted from DocumentPreviewViewController following MVC pattern
class DocumentPreviewContentView: UIView {
    
    // MARK: - Callbacks
    
    var onRecapture: (() -> Void)?
    var onToggleSide: ((Int) -> Void)?
    
    // MARK: - UI Components
    
    let scrollView = OkIDScrollView()
    let imageContainerView = UIView()
    let frontImageView = UIImageView()
    let backImageView = UIImageView()
    let toggleControl = UISegmentedControl(items: ["Front", "Back"])
    private let infoContainerView = UIView()
    private let infoContentStack = UIStackView()
    private let qualityStackView = UIStackView()
    private let analyzingRow = UIStackView()
    private let activityIndicator: UIActivityIndicatorView
    private let analyzingLabel = UILabel()
    private let recaptureButton = OkIDPrimaryButton(title: "Recapture Document", icon: "arrow.clockwise")
    private let timestampStack: UIStackView
    private var sidesStack: UIStackView?
    
    // MARK: - Properties
    
    private let hasBackImage: Bool
    private let primaryColor: UIColor
    
    // MARK: - Initialization
    
    init(hasBackImage: Bool, primaryColor: UIColor, timestampText: String) {
        self.hasBackImage = hasBackImage
        self.primaryColor = primaryColor
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.timestampStack = DocumentPreviewContentView.createInfoRow(icon: "clock", text: timestampText)
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .black
        
        // Image container with zoom capability
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageContainerView)
        
        frontImageView.contentMode = .scaleAspectFit
        frontImageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.addSubview(frontImageView)
        
        backImageView.contentMode = .scaleAspectFit
        backImageView.translatesAutoresizingMaskIntoConstraints = false
        backImageView.isHidden = true
        imageContainerView.addSubview(backImageView)
        
        // Toggle control (only if back image exists)
        if hasBackImage {
            toggleControl.selectedSegmentIndex = 0
            toggleControl.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toggleControl.selectedSegmentTintColor = .white
            toggleControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            toggleControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
            toggleControl.addTarget(self, action: #selector(toggleTapped), for: .valueChanged)
            toggleControl.translatesAutoresizingMaskIntoConstraints = false
            addSubview(toggleControl)
        }
        
        // Info container (pinned to bottom, height wraps content)
        infoContainerView.backgroundColor = .white
        infoContainerView.layer.cornerRadius = 20
        infoContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        infoContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoContainerView)
        
        // --- Vertical stack for info rows only (compact, no stretching) ---
        infoContentStack.axis = .vertical
        infoContentStack.spacing = 4
        infoContentStack.alignment = .leading
        infoContentStack.translatesAutoresizingMaskIntoConstraints = false
        infoContentStack.setContentHuggingPriority(.required, for: .vertical)
        infoContentStack.setContentCompressionResistancePriority(.required, for: .vertical)
        infoContainerView.addSubview(infoContentStack)
        
        // Row 1: Quality badges (fixed height — must not stretch)
        qualityStackView.axis = .horizontal
        qualityStackView.spacing = 8
        qualityStackView.alignment = .center
        qualityStackView.setContentHuggingPriority(.required, for: .vertical)
        qualityStackView.setContentCompressionResistancePriority(.required, for: .vertical)
        qualityStackView.heightAnchor.constraint(equalToConstant: 28).isActive = true
        infoContentStack.addArrangedSubview(qualityStackView)
        
        // Row 2: Analyzing indicator (shown while analyzing, hidden after)
        analyzingRow.axis = .horizontal
        analyzingRow.spacing = 8
        analyzingRow.alignment = .center
        analyzingRow.setContentHuggingPriority(.required, for: .vertical)
        analyzingRow.heightAnchor.constraint(equalToConstant: 20).isActive = true
        activityIndicator.color = primaryColor
        analyzingLabel.text = "Analyzing quality..."
        analyzingLabel.font = .systemFont(ofSize: 13)
        analyzingLabel.textColor = .gray
        analyzingRow.addArrangedSubview(activityIndicator)
        analyzingRow.addArrangedSubview(analyzingLabel)
        infoContentStack.addArrangedSubview(analyzingRow)
        
        // Row 3: Timestamp
        infoContentStack.addArrangedSubview(timestampStack)
        
        // Row 4: Sides info (if back exists)
        if hasBackImage {
            sidesStack = DocumentPreviewContentView.createInfoRow(
                icon: "arrow.left.arrow.right",
                text: "Front and back sides captured"
            )
            if let stack = sidesStack {
                infoContentStack.addArrangedSubview(stack)
            }
        }
        
        // Recapture button (NOT in the stack — pinned separately below)
        recaptureButton.translatesAutoresizingMaskIntoConstraints = false
        recaptureButton.addTarget(self, action: #selector(recaptureTapped), for: .touchUpInside)
        infoContainerView.addSubview(recaptureButton)
        
        // --- Constraints ---
        var constraints = [
            // Image scroll area
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: infoContainerView.topAnchor),
            
            imageContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            frontImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            frontImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            frontImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            frontImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            backImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            backImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            backImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            backImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            // Info container — pinned to bottom, height wraps content
            infoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            infoContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Info rows stack — pinned to top of container, hugs content
            infoContentStack.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 16),
            infoContentStack.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            infoContentStack.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -20),
            
            // Button — pinned between stack bottom and safe area bottom
            recaptureButton.topAnchor.constraint(equalTo: infoContentStack.bottomAnchor, constant: 12),
            recaptureButton.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            recaptureButton.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -20),
            recaptureButton.bottomAnchor.constraint(equalTo: infoContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ]
        
        if hasBackImage {
            constraints.append(contentsOf: [
                toggleControl.centerXAnchor.constraint(equalTo: centerXAnchor),
                toggleControl.bottomAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: -20),
                toggleControl.widthAnchor.constraint(equalToConstant: 200)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        // Initially show analyzing state
        activityIndicator.startAnimating()
        qualityStackView.isHidden = true
    }
    
    // MARK: - Public Methods
    
    /// Update quality badges after analysis completes
    func showQualityBadges(_ badges: [UIView]) {
        activityIndicator.stopAnimating()
        analyzingRow.isHidden = true
        qualityStackView.isHidden = false
        
        qualityStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for badge in badges {
            qualityStackView.addArrangedSubview(badge)
        }
    }
    
    // MARK: - Static Helpers
    
    static func createInfoRow(icon: String, text: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .gray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        stack.addArrangedSubview(iconView)
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(label)
        
        // Fix the row height so it never stretches
        stack.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        return stack
    }
    
    static func createQualityBadge(score: Double, label: String, qualityThreshold: Double) -> UIView {
        let qualityDescription = BlurDetection.getQualityDescription(blurScore: score)
        let isGood = score >= qualityThreshold
        let color = isGood ? UIColor.okidSuccess : UIColor.okidWarning
        
        let container = UIView()
        container.backgroundColor = color.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let iconView = UIImageView(image: UIImage(systemName: isGood ? "checkmark.circle" : "info.circle"))
        iconView.tintColor = color
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        stack.addArrangedSubview(iconView)
        
        let textLabel = UILabel()
        textLabel.text = "\(label): \(qualityDescription) (\(String(format: "%.1f", score)))"
        textLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        textLabel.textColor = color
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        
        return container
    }
    
    /// Create a resolution badge with ruler icon
    static func createResolutionBadge(size: CGSize) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let iconView = UIImageView(image: UIImage(systemName: "aspectratio"))
        iconView.tintColor = .gray
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        stack.addArrangedSubview(iconView)
        
        let textLabel = UILabel()
        textLabel.text = "\(Int(size.width))×\(Int(size.height))px"
        textLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        textLabel.textColor = .gray
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func toggleTapped() {
        let showingFront = toggleControl.selectedSegmentIndex == 0
        frontImageView.isHidden = !showingFront
        backImageView.isHidden = showingFront
        scrollView.zoomScale = 1.0
        onToggleSide?(toggleControl.selectedSegmentIndex)
    }
    
    @objc private func recaptureTapped() {
        onRecapture?()
    }
}
