import UIKit

/// Content view for liveness/selfie preview — all UI elements
/// Extracted from LivenessPreviewViewController following MVC pattern
class LivenessPreviewContentView: UIView {
    
    // MARK: - Callbacks
    
    var onRetake: (() -> Void)?
    
    // MARK: - UI Components
    
    let scrollView = OkIDScrollView()
    let imageContainerView = UIView()
    let selfieImageView = UIImageView()
    private let infoContainerView = UIView()
    private let metricsStackView = UIStackView()
    private let activityIndicator: UIActivityIndicatorView
    private let analyzingLabel = OkIDLabel()
    private let timestampStack: UIStackView
    private let retakeButton = OkIDPrimaryButton(title: "Retake Selfie", icon: "arrow.clockwise")
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor, timestampText: String) {
        self.activityIndicator = UIActivityIndicatorView(style: .medium)
        self.timestampStack = LivenessPreviewContentView.createInfoRow(icon: "clock", text: timestampText)
        super.init(frame: .zero)
        self.activityIndicator.color = primaryColor
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .black
        
        // Scroll view with zoom
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageContainerView)
        
        selfieImageView.contentMode = .scaleAspectFit
        selfieImageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.addSubview(selfieImageView)
        
        // Info container
        infoContainerView.backgroundColor = .white
        infoContainerView.layer.cornerRadius = 20
        infoContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        infoContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoContainerView)
        
        // Metrics
        metricsStackView.axis = .vertical
        metricsStackView.spacing = 8
        metricsStackView.translatesAutoresizingMaskIntoConstraints = false
        infoContainerView.addSubview(metricsStackView)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        infoContainerView.addSubview(activityIndicator)
        
        analyzingLabel.text = "Analyzing biometrics..."
        analyzingLabel.font = .systemFont(ofSize: 13)
        analyzingLabel.textColor = .gray
        analyzingLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainerView.addSubview(analyzingLabel)
        
        timestampStack.translatesAutoresizingMaskIntoConstraints = false
        infoContainerView.addSubview(timestampStack)
        
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
        infoContainerView.addSubview(retakeButton)
        
        NSLayoutConstraint.activate([
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
            
            selfieImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            selfieImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            selfieImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            selfieImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            infoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            infoContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            metricsStackView.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 20),
            metricsStackView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            metricsStackView.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -20),
            
            activityIndicator.topAnchor.constraint(equalTo: infoContainerView.topAnchor, constant: 20),
            activityIndicator.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            
            analyzingLabel.centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor),
            analyzingLabel.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 8),
            
            timestampStack.topAnchor.constraint(equalTo: metricsStackView.bottomAnchor, constant: 12),
            timestampStack.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            timestampStack.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -20),
            
            retakeButton.topAnchor.constraint(equalTo: timestampStack.bottomAnchor, constant: 20),
            retakeButton.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor, constant: 20),
            retakeButton.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor, constant: -20),
            retakeButton.bottomAnchor.constraint(equalTo: infoContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Initially show analyzing state
        activityIndicator.startAnimating()
        metricsStackView.isHidden = true
    }
    
    // MARK: - Public Methods
    
    /// Update metrics display after analysis completes
    func showMetrics(_ metricViews: [UIView]) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        metricsStackView.isHidden = false
        analyzingLabel.isHidden = true
        
        metricsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for metricView in metricViews {
            metricsStackView.addArrangedSubview(metricView)
        }
    }
    
    /// Create a metric row view
    static func createMetricRow(
        icon: String,
        iconColor: UIColor,
        label: String,
        value: String,
        valueColor: UIColor? = nil
    ) -> UIView {
        let container = UIView()
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        stack.addArrangedSubview(iconView)
        
        let labelView = OkIDLabel()
        labelView.text = "\(label): "
        labelView.font = .systemFont(ofSize: 12)
        labelView.textColor = .gray
        stack.addArrangedSubview(labelView)
        
        let valueLabel = OkIDLabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        valueLabel.textColor = valueColor ?? UIColor(white: 0.2, alpha: 1)
        stack.addArrangedSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
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
        
        let label = OkIDLabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        stack.addArrangedSubview(label)
        
        return stack
    }
    
    // MARK: - Actions
    
    @objc private func retakeTapped() {
        onRetake?()
    }
}
