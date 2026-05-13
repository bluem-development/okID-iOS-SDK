import Foundation

// MARK: - Form Data Module State

/// Represents the current state of the form data flow
enum FormDataModuleState {
    case idle
    case submitting
    case submitted(nextStep: String?)
    case error(message: String)
}

// MARK: - Form Data State Manager

/// Manages state for FormDataViewController following MVC pattern
/// Separates state management from the view controller
class FormDataState {
    
    // MARK: - State Properties
    
    var currentState: FormDataModuleState = .idle {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    /// Current field values keyed by field name
    var fieldValues: [String: String] = [:]
    
    // MARK: - Callbacks
    
    var onStateChanged: ((FormDataModuleState) -> Void)?
    
    // MARK: - Computed Properties
    
    var isSubmitting: Bool {
        if case .submitting = currentState { return true }
        return false
    }
    
    // MARK: - State Transitions
    
    func setFieldValue(_ value: String, for fieldName: String) {
        fieldValues[fieldName] = value
    }
    
    func getFieldValue(for fieldName: String) -> String? {
        return fieldValues[fieldName]
    }
    
    func startSubmitting() {
        currentState = .submitting
    }
    
    func completeSubmission(nextStep: String?) {
        currentState = .submitted(nextStep: nextStep)
    }
    
    func setError(_ message: String) {
        currentState = .error(message: message)
    }
    
    func reset() {
        currentState = .idle
        fieldValues = [:]
    }
}
