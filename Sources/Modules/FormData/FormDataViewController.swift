import UIKit

/// Form data collection module - Controller
/// Thin coordinator between FormDataManager (business logic),
/// FormDataState (state), and FormDataFormView (UI)
@MainActor
public class FormDataViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let formManager: FormDataManager
    private let formState: FormDataState
    private let formView: FormDataFormView
    
    // MARK: - Properties
    
    private let sdkConfig: OkIDSDKConfig
    private let onComplete: (String?) -> Void
    
    private var primaryColor: UIColor {
        return sdkConfig.theme.colors.primary
    }
    
    // MARK: - Initialization
    
    public init(
        verificationId: String,
        config: OkIDFormDataModuleConfig,
        sdkConfig: OkIDSDKConfig,
        onComplete: @escaping (String?) -> Void
    ) {
        self.sdkConfig = sdkConfig
        self.onComplete = onComplete
        
        // Create MVC components
        self.formManager = FormDataManager(
            verificationId: verificationId,
            config: config,
            sdkConfig: sdkConfig
        )
        self.formState = FormDataState()
        self.formView = FormDataFormView(theme: sdkConfig.theme)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Additional Information"
        view.backgroundColor = .okidSurface
        navigationItem.hidesBackButton = true
        
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        setupFormView()
        bindState()
        setupKeyboardDismissal()
        setupKeyboardObservers()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar(backgroundColor: primaryColor)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupFormView() {
        formView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formView)
        
        NSLayoutConstraint.activate([
            formView.topAnchor.constraint(equalTo: view.topAnchor),
            formView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Configure form with fields from manager
        formView.configure(
            fields: formManager.fields,
            placeholderProvider: { [weak self] field in
                self?.formManager.getPlaceholder(for: field) ?? ""
            },
            iconProvider: { [weak self] field in
                self?.formManager.getFieldIcon(for: field) ?? "textformat"
            },
            keyboardTypeProvider: { [weak self] field in
                self?.formManager.getKeyboardType(for: field) ?? 0
            },
            dateChangedTarget: self,
            dateChangedAction: #selector(dateChanged(_:)),
            dateFieldBeginTarget: self,
            dateFieldBeginAction: #selector(dateFieldEditingDidBegin(_:)),
            selectFieldBeginTarget: self,
            selectFieldBeginAction: #selector(selectFieldEditingDidBegin(_:)),
            dismissPickerTarget: self,
            dismissPickerAction: #selector(dismissPicker)
        )
        
        // Wire submit callback
        formView.onSubmit = { [weak self] in
            self?.submitForm()
        }
    }
    
    private func bindState() {
        formState.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .idle:
                formView.setSubmitting(false)
                
            case .submitting:
                formView.setSubmitting(true)
                
            case .submitted(let nextStep):
                formView.setSubmitting(false)
                onComplete(nextStep)
                
            case .error(let message):
                formView.setSubmitting(false)
                showError(message: message)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func submitForm() {
        // Collect current values from the view
        let fieldValues = formView.collectFieldValues()
        
        // Validate via manager
        let validation = formManager.validateForm(fieldValues: fieldValues)
        guard validation.isValid else {
            if let errorMessage = validation.errorMessage {
                showError(message: errorMessage)
            }
            return
        }
        
        // Update state and submit
        formState.startSubmitting()
        
        Task {
            do {
                let nextStep = try await formManager.submitForm(fieldValues: fieldValues)
                formState.completeSubmission(nextStep: nextStep)
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                formState.setError(okidError.errorDescription ?? error.localizedDescription)
            }
        }
    }
    
    // MARK: - Picker / Date Handling
    
    @objc private func dismissPicker() {
        view.endEditing(true)
    }
    
    @objc private func dateFieldEditingDidBegin(_ textField: OkIDTextField) {
        guard let fieldName = formView.textFields.first(where: { $0.value === textField })?.key else { return }
        guard let picker = formView.datePickers[fieldName] else { return }
        dateChanged(picker)
    }
    
    @objc private func selectFieldEditingDidBegin(_ textField: OkIDTextField) {
        guard let fieldName = formView.textFields.first(where: { $0.value === textField })?.key else { return }
        guard let picker = formView.pickerViews[fieldName] else { return }
        guard !picker.items.isEmpty else { return }
        
        if let current = textField.text, let idx = picker.items.firstIndex(of: current) {
            picker.selectRow(idx, inComponent: 0, animated: false)
        } else {
            picker.selectRow(0, inComponent: 0, animated: false)
            textField.text = picker.items[0]
        }
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        for (fieldName, picker) in formView.datePickers {
            if picker == sender {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                if let textField = formView.textFields[fieldName] {
                    textField.text = formatter.string(from: sender.date)
                }
                break
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        formView.adjustForKeyboard(height: keyboardFrame.height, duration: duration)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        formView.restoreFromKeyboard(duration: duration)
    }
    
    // MARK: - Helpers
    
    private func showError(message: String) {
        OkIDAlert.showError(message: message, from: self)
    }
}
