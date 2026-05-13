import UIKit

/// Pure UI view for the NFC input form
/// Contains all form fields, header, CAN container, scan button, and bottom button
class NFCInputFormView: UIView {
    
    // MARK: - Callbacks
    
    var onStartReading: (() -> Void)?
    var onScanMRZ: (() -> Void)?
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let fieldTheme: OkIDThemeConfig
    
    // MARK: - UI Elements
    
    let scrollView = OkIDScrollView()
    private let contentView = UIView()
    
    private(set) lazy var documentNumberTextField = OkIDTextField(theme: fieldTheme)
    private(set) lazy var dateOfBirthTextField = OkIDTextField(theme: fieldTheme)
    private(set) lazy var dateOfExpiryTextField = OkIDTextField(theme: fieldTheme)
    private(set) lazy var canTextField = OkIDTextField(theme: fieldTheme)
    private(set) lazy var startNFCButton = createBottomButton()
    
    var buttonBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    init(primaryColor: UIColor) {
        self.primaryColor = primaryColor
        
        // Build theme
        let base = OkIDThemeConfig.defaultTheme
        let colors = OkIDColorPalette(
            primary: primaryColor,
            secondary: base.colors.secondary,
            accent: base.colors.accent,
            warning: base.colors.warning,
            error: base.colors.error,
            background: base.colors.background,
            surface: base.colors.surface,
            text: base.colors.text,
            textSecondary: base.colors.textSecondary,
            border: base.colors.border
        )
        let branding = OkIDBrandingConfig(
            organizationName: base.branding.organizationName,
            logoImage: base.branding.logoImage,
            primaryColor: primaryColor,
            secondaryColor: base.branding.secondaryColor
        )
        self.fieldTheme = OkIDThemeConfig(
            colors: colors,
            typography: base.typography,
            spacing: base.spacing,
            branding: branding,
            borderRadius: base.borderRadius
        )
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Header
        let headerStack = createHeader()
        contentView.addSubview(headerStack)
        
        // Form fields
        let formStack = createFormFields()
        contentView.addSubview(formStack)
        
        // CAN container
        let canContainer = createCANContainer()
        contentView.addSubview(canContainer)
        
        // Scan MRZ button
        let scanButton = createScanButton()
        contentView.addSubview(scanButton)
        
        // Bottom button is added separately by the controller (outside scroll view)
        startNFCButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(startNFCButton)
        
        // Store bottom constraint for keyboard handling
        buttonBottomConstraint = startNFCButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startNFCButton.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            formStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 32),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            canContainer.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 24),
            canContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            canContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            scanButton.topAnchor.constraint(equalTo: canContainer.bottomAnchor, constant: 24),
            scanButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            scanButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            scanButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            startNFCButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            startNFCButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonBottomConstraint!,
        ])
    }
    
    // MARK: - Populate
    
    /// Populate fields from credentials
    func populate(documentNumber: String, dateOfBirth: String, dateOfExpiry: String, can: String?) {
        documentNumberTextField.text = documentNumber
        dateOfBirthTextField.text = dateOfBirth
        dateOfExpiryTextField.text = dateOfExpiry
        canTextField.text = can ?? ""
    }
    
    // MARK: - Field Values
    
    var documentNumberValue: String? { documentNumberTextField.text }
    var dateOfBirthValue: String? { dateOfBirthTextField.text }
    var dateOfExpiryValue: String? { dateOfExpiryTextField.text }
    var canValue: String? { canTextField.text }
    
    // MARK: - UI Construction
    
    private func createHeader() -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: "wave.3.right"))
        icon.tintColor = primaryColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "Passport Authentication"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        let subtitleLabel = OkIDLabel()
        subtitleLabel.text = "Enter document details from passport MRZ"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .okidGray600
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }
    
    private func createFormFields() -> UIStackView {
        documentNumberTextField.placeholder = "e.g., AB1234567"
        documentNumberTextField.autocapitalizationType = .allCharacters
        let docField = createTextField(
            textField: documentNumberTextField,
            label: "Document Number",
            icon: "person.text.rectangle.fill"
        )
        
        dateOfBirthTextField.placeholder = "DD.MM.YY (e.g., 29.01.78)"
        dateOfBirthTextField.keyboardType = .numberPad
        let dobField = createTextField(
            textField: dateOfBirthTextField,
            label: "Date of Birth",
            icon: "birthday.cake.fill"
        )
        
        dateOfExpiryTextField.placeholder = "DD.MM.YY (e.g., 30.06.29)"
        dateOfExpiryTextField.keyboardType = .numberPad
        let expiryField = createTextField(
            textField: dateOfExpiryTextField,
            label: "Date of Expiry",
            icon: "calendar.badge.clock"
        )
        
        let stack = UIStackView(arrangedSubviews: [docField, dobField, expiryField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        return stack
    }
    
    private func createTextField(textField: OkIDTextField, label: String, icon: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = OkIDLabel(theme: fieldTheme, style: .fieldLabel)
        labelView.text = label
        
        if let okidField = textField as? OkIDTextField {
            okidField.setIcon(systemName: icon)
        }
        
        container.addSubview(labelView)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        return container
    }
    
    private func createCANContainer() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .okidWarningLight
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.okidWarningBorder.cgColor
        
        let iconView = UIImageView(image: UIImage(systemName: "key.fill"))
        iconView.tintColor = .okidWarningIcon
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = OkIDLabel()
        titleLabel.text = "CAN (Card Access Number)"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .okidWarningTitle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = OkIDLabel()
        subtitleLabel.text = "6-digit code on front of passport (required for Dutch passports)"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .okidGray600
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        canTextField.keyboardType = .numberPad
        canTextField.translatesAutoresizingMaskIntoConstraints = false
        canTextField.borderStyle = .none
        canTextField.font = .systemFont(ofSize: 16)
        canTextField.backgroundColor = .white
        canTextField.textColor = .black
        canTextField.layer.cornerRadius = 12
        canTextField.layer.borderWidth = 1
        canTextField.layer.borderColor = UIColor.okidGray400.cgColor
        
        canTextField.attributedPlaceholder = NSAttributedString(
            string: "CAN (Optional)",
            attributes: [.foregroundColor: UIColor.okidGray500]
        )
        
        canTextField.isUserInteractionEnabled = true
        canTextField.isEnabled = true
        canTextField.clearButtonMode = .whileEditing
        
        // Add pin icon with padding
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 50))
        let canIconView = UIImageView(image: UIImage(systemName: "numbers.rectangle.fill"))
        canIconView.tintColor = .okidGray600
        canIconView.contentMode = .scaleAspectFit
        canIconView.frame = CGRect(x: 12, y: 13, width: 20, height: 20)
        leftPaddingView.addSubview(canIconView)
        canTextField.leftView = leftPaddingView
        canTextField.leftViewMode = .always
        
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        canTextField.rightView = rightPaddingView
        canTextField.rightViewMode = .always
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(canTextField)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            canTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            canTextField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            canTextField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            canTextField.heightAnchor.constraint(equalToConstant: 50),
            canTextField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        
        return container
    }
    
    private func createScanButton() -> OkIDButton {
        let icon = UIImage(systemName: "camera.fill")
        let config = OkIDButtonConfig(
            backgroundColor: .okidBlueLight,
            titleColor: .okidBlueTitle,
            font: .systemFont(ofSize: 16, weight: .semibold),
            cornerRadius: 12,
            borderWidth: 1,
            borderColor: .okidBlueBorder,
            icon: icon
        )
        let button = OkIDButton(config: config)
        button.setTitle("Scan Passport MRZ", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scanMRZTapped), for: .touchUpInside)
        
        return button
    }
    
    private func createBottomButton() -> OkIDButton {
        let icon = UIImage(systemName: "wave.3.right")
        let button = OkIDButton(config: .primary(color: primaryColor, icon: icon))
        button.setTitle("Start NFC Reading", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startReadingTapped), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Actions
    
    @objc private func scanMRZTapped() {
        onScanMRZ?()
    }
    
    @objc private func startReadingTapped() {
        onStartReading?()
    }
}
