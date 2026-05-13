import UIKit

// MARK: - Document Initial View

/// Initial screen for document capture with instructions
/// Extracted from DocumentViewController following proper MVC pattern
internal class DocumentInitialView: UIView {
    
    // MARK: - Properties
    
    private let side: String
    private let theme: OkIDThemeConfig
    var onOpenCameraTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = OkIDLabel()
    private let visualGuide = DocumentVisualGuideView()
    private let instructionsStack = UIStackView()
    private let buttonContainer = UIView()
    private let openCameraButton: OkIDButton
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    
    init(side: String, theme: OkIDThemeConfig) {
        self.side = side
        self.theme = theme
        
        let cameraIcon = UIImage(systemName: "camera.fill")
        self.openCameraButton = OkIDButton(config: .primary(color: theme.colors.primary, icon: cameraIcon))
        
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        configureContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        // Configure content stack
        contentStack.axis = .vertical
        contentStack.spacing = 32
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure button container
        buttonContainer.backgroundColor = .white
        buttonContainer.layer.shadowColor = UIColor.black.cgColor
        buttonContainer.layer.shadowOpacity = 0.05
        buttonContainer.layer.shadowRadius = 10
        buttonContainer.layer.shadowOffset = CGSize(width: 0, height: -2)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure button
        openCameraButton.setTitle("Open Camera", for: .normal)
        openCameraButton.translatesAutoresizingMaskIntoConstraints = false
        openCameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        
        // Setup instructions
        setupInstructions()
        
        // Add subviews
        scrollView.addSubview(contentStack)
        buttonContainer.addSubview(openCameraButton)
        buttonContainer.addSubview(loadingIndicator)
        
        addSubview(scrollView)
        addSubview(buttonContainer)
    }
    
    private func setupConstraints() {
        // Center content vertically with lower priority so it can compress if needed
        let centerYConstraint = contentStack.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        centerYConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor),
            
            // Content stack - centered with compression support
            centerYConstraint,
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            // Button container
            buttonContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 128),
            
            // Button
            openCameraButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: 16),
            openCameraButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 16),
            openCameraButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16),
            
            // Loading indicator (centered in button)
            loadingIndicator.centerXAnchor.constraint(equalTo: openCameraButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: openCameraButton.centerYAnchor)
        ])
    }
    
    private func configureContent() {
        // Title
        let sideText = side == "front" ? "Front" : "Back"
        titleLabel.text = "Scan \(sideText) Side"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        // Configure visual guide
        visualGuide.configure(with: theme.colors.primary)
        
        // Add arranged subviews
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(visualGuide)
        contentStack.addArrangedSubview(instructionsStack)
    }
    
    private func setupInstructions() {
        instructionsStack.axis = .vertical
        instructionsStack.spacing = 12
        instructionsStack.alignment = .leading
        
        let instructions = [
            "Fit entire document inside the frame",
            "Ensure all corners are visible",
            "Use good lighting, avoid glare",
            "Hold phone steady"
        ]
        
        for instruction in instructions {
            let instructionView = DocumentInstructionView(text: instruction)
            instructionsStack.addArrangedSubview(instructionView)
        }
    }
    
    // MARK: - Public Methods
    
    func showLoading() {
        openCameraButton.isEnabled = false
        openCameraButton.alpha = 0.7
        openCameraButton.setTitle("", for: .normal)
        loadingIndicator.startAnimating()
    }
    
    func hideLoading() {
        openCameraButton.isEnabled = true
        openCameraButton.alpha = 1.0
        openCameraButton.setTitle("Open Camera", for: .normal)
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Actions
    
    @objc private func cameraButtonTapped() {
        showLoading()
        onOpenCameraTapped?()
    }
}

// MARK: - Document Visual Guide View

/// Visual guide showing document outline
internal class DocumentVisualGuideView: UIView {
    
    private let container = UIView()
    private let innerContainer = UIView()
    private let icon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        innerContainer.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        container.layer.borderWidth = 3
        container.layer.cornerRadius = 12
        
        innerContainer.layer.borderWidth = 2
        innerContainer.layer.cornerRadius = 8
        
        icon.image = UIImage(systemName: "creditcard")
        icon.contentMode = .scaleAspectFit
        
        addSubview(container)
        container.addSubview(innerContainer)
        innerContainer.addSubview(icon)
        
        NSLayoutConstraint.activate([
            // Landscape orientation - width is greater than height
            heightAnchor.constraint(equalToConstant: 180),
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1.6), // ID card aspect ratio
            
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            innerContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            innerContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            innerContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            innerContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            icon.centerXAnchor.constraint(equalTo: innerContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: innerContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    func configure(with primaryColor: UIColor) {
        container.layer.borderColor = primaryColor.cgColor
        innerContainer.layer.borderColor = primaryColor.cgColor
        icon.tintColor = primaryColor.withAlphaComponent(0.5)
    }
}

// MARK: - Document Instruction View

/// Single instruction row with bullet point
internal class DocumentInstructionView: UIView {
    
    private let bullet = UIView()
    private let label = OkIDLabel()
    
    init(text: String) {
        super.init(frame: .zero)
        setupViews(with: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(with text: String) {
        translatesAutoresizingMaskIntoConstraints = false
        
        bullet.backgroundColor = .okidSecondary
        bullet.layer.cornerRadius = 3
        bullet.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .okidSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(bullet)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            bullet.leadingAnchor.constraint(equalTo: leadingAnchor),
            bullet.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            bullet.widthAnchor.constraint(equalToConstant: 6),
            bullet.heightAnchor.constraint(equalToConstant: 6),
            
            label.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
