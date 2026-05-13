import UIKit

// MARK: - Terms Content View

/// Main view for the Terms module
/// Handles all UI construction and layout following MVC pattern
/// Communicates back to controller via callbacks
class TermsContentView: UIView {
    
    // MARK: - Callbacks
    
    var onCheckboxTapped: (() -> Void)?
    var onContinueTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentLabel = OkIDLabel()
    private let checkboxContainer = UIView()
    private let checkbox = UIButton(type: .custom)
    private let checkboxLabel = OkIDLabel()
    private let bottomContainer = UIView()
    private let errorContainer = UIView()
    private let errorIcon = UIImageView()
    private let errorLabel = OkIDLabel()
    private let helperLabel = OkIDLabel()
    private let continueButton: OkIDButton
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    
    private let theme: OkIDThemeConfig
    private let acceptanceRequired: Bool
    private let termsContent: String
    private let buttonTitle: String
    
    // MARK: - Initialization
    
    init(
        theme: OkIDThemeConfig,
        acceptanceRequired: Bool,
        termsContent: String,
        buttonTitle: String
    ) {
        self.theme = theme
        self.acceptanceRequired = acceptanceRequired
        self.termsContent = termsContent
        self.buttonTitle = buttonTitle
        self.continueButton = OkIDButton(config: .primary(color: theme.colors.primary))
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .white
        
        // Scroll view for terms content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Content label
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.7
        contentLabel.attributedText = NSAttributedString(
            string: termsContent,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.okidTextDark,
                .paragraphStyle: paragraphStyle
            ]
        )
        scrollView.addSubview(contentLabel)
        
        // Checkbox section (if acceptance required)
        if acceptanceRequired {
            setupCheckboxSection()
        }
        
        // Bottom container
        setupBottomContainer()
        
        // Layout
        setupConstraints()
    }
    
    private func setupCheckboxSection() {
        checkboxContainer.backgroundColor = .okidBackgroundLightAlt
        checkboxContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkboxContainer)
        
        // Checkbox button
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        checkbox.tintColor = theme.colors.primary
        checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkboxContainer.addSubview(checkbox)
        
        // Checkbox label
        checkboxLabel.text = "I have read and agree to the terms and conditions"
        checkboxLabel.font = .systemFont(ofSize: 15)
        checkboxLabel.textColor = .black
        checkboxLabel.numberOfLines = 0
        checkboxLabel.translatesAutoresizingMaskIntoConstraints = false
        checkboxContainer.addSubview(checkboxLabel)
        
        // Add tap gesture to container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped))
        checkboxContainer.addGestureRecognizer(tapGesture)
    }
    
    private func setupBottomContainer() {
        bottomContainer.backgroundColor = .white
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomContainer)
        
        // Error container
        errorContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorContainer.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        errorContainer.layer.borderWidth = 1
        errorContainer.layer.cornerRadius = 8
        errorContainer.isHidden = true
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(errorContainer)
        
        errorIcon.image = UIImage(systemName: "exclamationmark.circle")
        errorIcon.tintColor = .systemRed
        errorIcon.contentMode = .scaleAspectFit
        errorIcon.translatesAutoresizingMaskIntoConstraints = false
        errorContainer.addSubview(errorIcon)
        
        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorContainer.addSubview(errorLabel)
        
        // Helper label
        helperLabel.text = "Please accept the terms to continue"
        helperLabel.font = .systemFont(ofSize: 13)
        helperLabel.textColor = .okidGray600
        helperLabel.textAlignment = .center
        helperLabel.isHidden = true
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(helperLabel)
        
        // Continue button
        continueButton.setTitle(buttonTitle, for: .normal)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(continueButton)
        
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ]
        
        if acceptanceRequired {
            constraints.append(contentsOf: [
                scrollView.bottomAnchor.constraint(equalTo: checkboxContainer.topAnchor),
                
                checkboxContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                checkboxContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                checkboxContainer.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),
                
                checkbox.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor, constant: 20),
                checkbox.topAnchor.constraint(equalTo: checkboxContainer.topAnchor, constant: 20),
                checkbox.bottomAnchor.constraint(equalTo: checkboxContainer.bottomAnchor, constant: -20),
                checkbox.widthAnchor.constraint(equalToConstant: 24),
                checkbox.heightAnchor.constraint(equalToConstant: 24),
                
                checkboxLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 16),
                checkboxLabel.trailingAnchor.constraint(equalTo: checkboxContainer.trailingAnchor, constant: -20),
                checkboxLabel.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor),
            ])
        } else {
            constraints.append(
                scrollView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
            )
        }
        
        constraints.append(contentsOf: [
            bottomContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            helperLabel.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 20),
            helperLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            helperLabel.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 16),
            continueButton.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            
            // Error container
            errorContainer.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 20),
            errorContainer.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            errorContainer.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            
            errorIcon.leadingAnchor.constraint(equalTo: errorContainer.leadingAnchor, constant: 12),
            errorIcon.topAnchor.constraint(equalTo: errorContainer.topAnchor, constant: 12),
            errorIcon.widthAnchor.constraint(equalToConstant: 20),
            errorIcon.heightAnchor.constraint(equalToConstant: 20),
            
            errorLabel.leadingAnchor.constraint(equalTo: errorIcon.trailingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(equalTo: errorContainer.trailingAnchor, constant: -12),
            errorLabel.topAnchor.constraint(equalTo: errorContainer.topAnchor, constant: 12),
            errorLabel.bottomAnchor.constraint(equalTo: errorContainer.bottomAnchor, constant: -12),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Public Update Methods
    
    /// Update checkbox visual state
    func setAccepted(_ accepted: Bool) {
        checkbox.isSelected = accepted
    }
    
    /// Update the view for submitting state
    func setSubmitting(_ submitting: Bool, canProceed: Bool) {
        continueButton.isEnabled = !submitting && canProceed
        
        if submitting {
            continueButton.setTitle("", for: .normal)
            loadingIndicator.startAnimating()
        } else {
            continueButton.setTitle(buttonTitle, for: .normal)
            loadingIndicator.stopAnimating()
        }
    }
    
    /// Show error message in the error container
    func showError(_ message: String) {
        errorLabel.text = message
        errorContainer.isHidden = false
        helperLabel.isHidden = true
    }
    
    /// Show helper text (when acceptance not yet checked)
    func showHelper() {
        errorContainer.isHidden = true
        helperLabel.isHidden = false
    }
    
    /// Hide both error and helper
    func hideMessages() {
        errorContainer.isHidden = true
        helperLabel.isHidden = true
    }
    
    // MARK: - Actions
    
    @objc private func checkboxTapped() {
        onCheckboxTapped?()
    }
    
    @objc private func continueTapped() {
        onContinueTapped?()
    }
}
