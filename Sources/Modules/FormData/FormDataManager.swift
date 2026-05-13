import Foundation

private let logger = Logger.formData

// MARK: - Form Data Manager

/// Manages business logic for form data collection and submission
/// Extracted from FormDataViewController following proper MVC pattern
/// Handles: validation, API calls, field configuration
class FormDataManager {
    
    // MARK: - Properties
    
    private let verificationId: String
    private let config: OkIDFormDataModuleConfig
    private let sdkConfig: OkIDSDKConfig
    private let apiClient: VerificationAPIClient
    
    // MARK: - Initialization
    
    init(
        verificationId: String,
        config: OkIDFormDataModuleConfig,
        sdkConfig: OkIDSDKConfig
    ) {
        self.verificationId = verificationId
        self.config = config
        self.sdkConfig = sdkConfig
        self.apiClient = VerificationAPIClient(config: sdkConfig)
        self.apiClient.setVerificationId(verificationId)
    }
    
    // MARK: - Form Fields
    
    var fields: [OkIDFormField] {
        return config.fields
    }
    
    // MARK: - Validation
    
    /// Validate all form fields and return result
    func validateForm(fieldValues: [String: String]) -> (isValid: Bool, errorMessage: String?) {
        for field in config.fields {
            if field.required {
                guard let text = fieldValues[field.name], !text.isEmpty else {
                    return (false, "\(field.label) is required")
                }
                
                // Type-specific validation
                switch field.type {
                case "email":
                    if !isValidEmail(text) {
                        return (false, "Please enter a valid email address")
                    }
                case "phone":
                    if !isValidPhone(text) {
                        return (false, "Please enter a valid phone number")
                    }
                case "number":
                    if !isValidNumber(text) {
                        return (false, "Please enter a valid number")
                    }
                case "date":
                    if !isValidDate(text) {
                        return (false, "Please select a valid date")
                    }
                default:
                    break
                }
            }
        }
        
        return (true, nil)
    }
    
    // MARK: - Submission
    
    /// Submit form data to server
    func submitForm(fieldValues: [String: String]) async throws -> String? {
        logger.debug("Submitting form data for verification: \(verificationId)")
        
        let answers = config.fields.map { field -> OkIDFormAnswer in
            let value = fieldValues[field.name] ?? ""
            return OkIDFormAnswer(questionId: field.name, answer: value)
        }
        
        do {
            let response = try await apiClient.submitFormData(
                verificationId: verificationId,
                answers: answers
            )
            
            logger.debug("Form submission successful: \(response.status)")
            return response.nextStep
            
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "FormDataManager.submitForm",
                severity: .error
            )
            throw okidError
        }
    }
    
    // MARK: - Field Configuration Helpers
    
    /// Get placeholder text for a field
    func getPlaceholder(for field: OkIDFormField) -> String {
        switch field.type {
        case "email":
            return "e.g., user@example.com"
        case "phone":
            return "e.g., +1234567890"
        case "number":
            return "Enter number"
        case "date":
            return "Select date"
        case "select":
            return "Select \(field.label.lowercased())"
        default:
            return "Enter \(field.label.lowercased())"
        }
    }
    
    /// Get icon name for a field type
    func getFieldIcon(for field: OkIDFormField) -> String {
        switch field.type {
        case "email":
            return "envelope"
        case "number":
            return "number"
        case "date":
            return "calendar"
        case "select":
            return "chevron.down.circle"
        case "phone":
            return "phone"
        default:
            return "textformat"
        }
    }
    
    /// Get keyboard type for a field
    func getKeyboardType(for field: OkIDFormField) -> Int {
        // Returns UIKeyboardType raw values to avoid UIKit dependency
        switch field.type {
        case "email":
            return 7 // .emailAddress
        case "number":
            return 4 // .numberPad
        case "phone":
            return 5 // .phonePad
        default:
            return 0 // .default
        }
    }
    
    // MARK: - Private Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[+]?[0-9]{10,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: phone.replacingOccurrences(of: " ", with: ""))
    }
    
    private func isValidNumber(_ number: String) -> Bool {
        return Double(number) != nil
    }
    
    private func isValidDate(_ date: String) -> Bool {
        return !date.isEmpty
    }
}
