import UIKit

// MARK: - Form Data Form View

/// Main form view for the FormData module
/// Handles all UI construction and layout following MVC pattern
/// Communicates back to controller via callbacks
class FormDataFormView: UIView {
    
    // MARK: - Callbacks
    
    var onSubmit: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = OkIDScrollView()
    private let contentStackView = UIStackView()
    private let submitButton = OkIDPrimaryButton(title: "Submit Information", icon: nil)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var submitButtonBottomConstraint: NSLayoutConstraint?
    private(set) var textFields: [String: OkIDTextField] = [:]
    private(set) var datePickers: [String: OkIDDatePicker] = [:]
    private(set) var pickerViews: [String: OkIDStringPickerView] = [:]
    
    // MARK: - Properties
    
    private let theme: OkIDThemeConfig
    
    // MARK: - Initialization
    
    init(theme: OkIDThemeConfig) {
        self.theme = theme
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    /// Build the form with the given fields and manager configuration
    func configure(
        fields: [OkIDFormField],
        placeholderProvider: (OkIDFormField) -> String,
        iconProvider: (OkIDFormField) -> String,
        keyboardTypeProvider: (OkIDFormField) -> Int,
        dateChangedTarget: Any,
        dateChangedAction: Selector,
        dateFieldBeginTarget: Any,
        dateFieldBeginAction: Selector,
        selectFieldBeginTarget: Any,
        selectFieldBeginAction: Selector,
        dismissPickerTarget: Any,
        dismissPickerAction: Selector
    ) {
        setupLayout()
        
        for field in fields {
            let fieldView = buildField(
                field,
                placeholder: placeholderProvider(field),
                iconName: iconProvider(field),
                keyboardType: UIKeyboardType(rawValue: keyboardTypeProvider(field)) ?? .default,
                dateChangedTarget: dateChangedTarget,
                dateChangedAction: dateChangedAction,
                dateFieldBeginTarget: dateFieldBeginTarget,
                dateFieldBeginAction: dateFieldBeginAction,
                selectFieldBeginTarget: selectFieldBeginTarget,
                selectFieldBeginAction: selectFieldBeginAction,
                dismissPickerTarget: dismissPickerTarget,
                dismissPickerAction: dismissPickerAction
            )
            contentStackView.addArrangedSubview(fieldView)
        }
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        backgroundColor = .clear
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.backgroundColor = .clear
        addSubview(scrollView)
        
        // Content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setColor(theme.colors.primary)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        addSubview(submitButton)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        submitButton.addSubview(activityIndicator)
        
        // Store submit button bottom constraint for keyboard handling
        submitButtonBottomConstraint = submitButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor),
            
            // Content stack view
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),
            
            // Submit button
            submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            submitButtonBottomConstraint!,
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
        ])
    }
    
    // MARK: - Field Building
    
    private func buildField(
        _ field: OkIDFormField,
        placeholder: String,
        iconName: String,
        keyboardType: UIKeyboardType,
        dateChangedTarget: Any,
        dateChangedAction: Selector,
        dateFieldBeginTarget: Any,
        dateFieldBeginAction: Selector,
        selectFieldBeginTarget: Any,
        selectFieldBeginAction: Selector,
        dismissPickerTarget: Any,
        dismissPickerAction: Selector
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Label above text field
        let labelView = OkIDLabel(theme: theme, style: .fieldLabel)
        labelView.text = field.label + (field.required ? " *" : "")
        
        let textField = OkIDTextField(
            theme: theme,
            iconSystemName: iconName
        )
        textField.keyboardType = keyboardType
        textField.placeholder = placeholder
        
        // Handle special field types
        if field.type == "date" {
            setupDatePicker(
                for: textField,
                fieldName: field.name,
                dateChangedTarget: dateChangedTarget,
                dateChangedAction: dateChangedAction,
                dateFieldBeginTarget: dateFieldBeginTarget,
                dateFieldBeginAction: dateFieldBeginAction,
                dismissPickerTarget: dismissPickerTarget,
                dismissPickerAction: dismissPickerAction
            )
        } else if field.type == "select" {
            setupPickerView(
                for: textField,
                field: field,
                selectFieldBeginTarget: selectFieldBeginTarget,
                selectFieldBeginAction: selectFieldBeginAction,
                dismissPickerTarget: dismissPickerTarget,
                dismissPickerAction: dismissPickerAction
            )
        }
        
        container.addSubview(labelView)
        container.addSubview(textField)
        textFields[field.name] = textField
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Date Picker Setup
    
    private func setupDatePicker(
        for textField: OkIDTextField,
        fieldName: String,
        dateChangedTarget: Any,
        dateChangedAction: Selector,
        dateFieldBeginTarget: Any,
        dateFieldBeginAction: Selector,
        dismissPickerTarget: Any,
        dismissPickerAction: Selector
    ) {
        let datePicker = OkIDDatePicker(theme: theme, mode: .date)
        datePicker.maximumDate = Date()
        datePicker.minimumDate = Calendar.current.date(from: DateComponents(year: 1900))
        datePicker.addTarget(dateChangedTarget, action: dateChangedAction, for: .valueChanged)
        
        datePickers[fieldName] = datePicker
        textField.addTarget(dateFieldBeginTarget, action: dateFieldBeginAction, for: .editingDidBegin)
        
        // Combine toolbar + picker into a single inputView to avoid
        // the gap iOS 26 inserts between inputAccessoryView and inputView.
        textField.inputView = OkIDPickerInputView(
            theme: theme,
            toolbarStyle: .closeLeft,
            picker: datePicker,
            target: dismissPickerTarget,
            action: dismissPickerAction
        )
    }
    
    // MARK: - Picker View Setup
    
    private func setupPickerView(
        for textField: OkIDTextField,
        field: OkIDFormField,
        selectFieldBeginTarget: Any,
        selectFieldBeginAction: Selector,
        dismissPickerTarget: Any,
        dismissPickerAction: Selector
    ) {
        let options = field.options ?? []
        let pickerView = OkIDStringPickerView(items: options, theme: theme)
        pickerView.onSelectionChanged = { [weak textField] _, selectedValue in
            textField?.text = selectedValue
        }
        
        pickerViews[field.name] = pickerView
        textField.addTarget(selectFieldBeginTarget, action: selectFieldBeginAction, for: .editingDidBegin)
        
        // Combine toolbar + picker into a single inputView to avoid
        // the gap iOS 26 inserts between inputAccessoryView and inputView.
        textField.inputView = OkIDPickerInputView(
            theme: theme,
            toolbarStyle: .closeLeft,
            picker: pickerView,
            target: dismissPickerTarget,
            action: dismissPickerAction
        )
    }
    
    // MARK: - Public Methods
    
    /// Collect all current field values from text fields
    func collectFieldValues() -> [String: String] {
        var values: [String: String] = [:]
        for (name, textField) in textFields {
            values[name] = textField.text ?? ""
        }
        return values
    }
    
    /// Update submit button for submitting / idle state
    func setSubmitting(_ submitting: Bool) {
        if submitting {
            submitButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
            submitButton.isEnabled = false
        } else {
            submitButton.setTitle("Submit Information", for: .normal)
            activityIndicator.stopAnimating()
            submitButton.isEnabled = true
        }
    }
    
    /// Adjust submit button position for keyboard
    func adjustForKeyboard(height: CGFloat, duration: Double) {
        submitButtonBottomConstraint?.constant = -(height + 16)
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    /// Restore submit button position when keyboard hides
    func restoreFromKeyboard(duration: Double) {
        submitButtonBottomConstraint?.constant = -16
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    
    @objc private func submitTapped() {
        onSubmit?()
    }
}
