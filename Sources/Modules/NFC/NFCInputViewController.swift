//
//  NFCInputViewController.swift
//  OkIDVerificationSDK
//
//  NFC input screen for entering passport credentials
//  Refactored to MVC: thin controller coordinating NFCManager, NFCInputState, and NFCInputFormView

import UIKit

/// NFC input screen for entering passport credentials
/// Controller only — delegates UI to NFCInputFormView, business logic to NFCManager
class NFCInputViewController: UIViewController {
    
    // MARK: - MVC Components
    
    private let nfcManager = NFCManager()
    private let inputState = NFCInputState()
    private let formView: NFCInputFormView
    
    // MARK: - Properties
    
    private let primaryColor: UIColor
    private let onStart: (OkIDPassportCredentials) -> Void
    private let onCancel: () -> Void
    private let initialCredentials: OkIDPassportCredentials?
    
    // MARK: - Initialization
    
    init(
        onStart: @escaping (OkIDPassportCredentials) -> Void,
        onCancel: @escaping () -> Void,
        primaryColor: UIColor,
        initialCredentials: OkIDPassportCredentials? = nil
    ) {
        self.onStart = onStart
        self.onCancel = onCancel
        self.primaryColor = primaryColor
        self.initialCredentials = initialCredentials
        self.formView = NFCInputFormView(primaryColor: primaryColor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFormView()
        setupNavigation()
        bindCallbacks()
        loadDefaults()
        setupKeyboardDismissal()
        setupKeyboardObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
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
    }
    
    private func setupNavigation() {
        title = "Passport NFC Reader"
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func bindCallbacks() {
        // Wire form view callbacks to controller actions
        formView.onStartReading = { [weak self] in self?.startReading() }
        formView.onScanMRZ = { [weak self] in self?.scanMRZ() }
        
        // Wire text field delegates
        formView.dateOfBirthTextField.delegate = self
        formView.dateOfExpiryTextField.delegate = self
        formView.canTextField.delegate = self
    }
    
    private func loadDefaults() {
        if let credentials = initialCredentials {
            formView.populate(
                documentNumber: credentials.documentNumber,
                dateOfBirth: nfcManager.formatDateToDDMMYY(credentials.dateOfBirth),
                dateOfExpiry: nfcManager.formatDateToDDMMYY(credentials.dateOfExpiry),
                can: credentials.can
            )
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        view.endEditing(true)
        onCancel()
    }
    
    private func scanMRZ() {
        view.endEditing(true)
        
        let mrzScanner = MrzCameraViewController(
            primaryColor: primaryColor,
            onDetected: { [weak self] credentials in
                self?.fillFromMRZ(credentials)
            },
            onCancel: {
                // No action needed — MrzCameraViewController dismisses itself
            }
        )
        
        mrzScanner.modalPresentationStyle = .fullScreen
        present(mrzScanner, animated: true)
    }
    
    private func startReading() {
        view.endEditing(true)
        
        let isValid = nfcManager.validateForm(
            documentNumber: formView.documentNumberValue,
            dateOfBirth: formView.dateOfBirthValue,
            dateOfExpiry: formView.dateOfExpiryValue,
            can: formView.canValue
        )
        
        guard isValid else {
            showAlert(title: "Invalid Input", message: "Please fill in all required fields or provide a 6-digit CAN.")
            return
        }
        
        do {
            let credentials = try nfcManager.buildCredentials(
                documentNumber: formView.documentNumberValue,
                dateOfBirth: formView.dateOfBirthValue,
                dateOfExpiry: formView.dateOfExpiryValue,
                can: formView.canValue
            )
            onStart(credentials)
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "NFCInputViewController.startReading",
                severity: .error
            )
            showAlert(title: "Invalid Date", message: okidError.errorDescription ?? "Please enter valid dates in DD.MM.YY format.")
        }
    }
    
    // MARK: - MRZ Fill
    
    private func fillFromMRZ(_ credentials: OkIDPassportCredentials) {
        formView.populate(
            documentNumber: credentials.documentNumber,
            dateOfBirth: nfcManager.formatDateToDDMMYY(credentials.dateOfBirth),
            dateOfExpiry: nfcManager.formatDateToDDMMYY(credentials.dateOfExpiry),
            can: nil
        )
        
        // Auto-proceed if valid
        let isValid = nfcManager.validateForm(
            documentNumber: formView.documentNumberValue,
            dateOfBirth: formView.dateOfBirthValue,
            dateOfExpiry: formView.dateOfExpiryValue,
            can: formView.canValue
        )
        
        if isValid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.startReading()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        OkIDAlert.show(title: title, message: message, from: self)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        formView.buttonBottomConstraint?.constant = -keyboardFrame.height - 16
        
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
        
        // Scroll to active text field
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            guard let self = self else { return }
            
            let activeField = [
                self.formView.documentNumberTextField,
                self.formView.dateOfBirthTextField,
                self.formView.dateOfExpiryTextField,
                self.formView.canTextField
            ].first { $0.isFirstResponder }
            
            if let field = activeField {
                let fieldFrame = field.convert(field.bounds, to: self.formView.scrollView)
                let visibleRect = CGRect(x: 0, y: fieldFrame.origin.y - 20,
                                         width: fieldFrame.width, height: fieldFrame.height + 40)
                self.formView.scrollView.scrollRectToVisible(visibleRect, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        formView.buttonBottomConstraint?.constant = -16
        
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate

extension NFCInputViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Date formatting for DOB and expiry fields
        if textField == formView.dateOfBirthTextField || textField == formView.dateOfExpiryTextField {
            let currentText = textField.text ?? ""
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
            let formatted = nfcManager.formatDateInput(updatedText)
            
            textField.text = formatted
            
            DispatchQueue.main.async {
                if let newPosition = textField.position(from: textField.endOfDocument, offset: 0) {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
            
            return false
        }
        
        // CAN field - limit to 6 digits
        if textField == formView.canTextField {
            let currentText = textField.text ?? ""
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
            let digitsOnly = updatedText.filter { $0.isNumber }
            
            if digitsOnly.count <= 6 {
                textField.text = digitsOnly
                
                DispatchQueue.main.async {
                    if let newPosition = textField.position(from: textField.endOfDocument, offset: 0) {
                        textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            
            return false
        }
        
        return true
    }
}
