import Foundation

// MARK: - Validation State Enum

/// Represents the current state of the validation flow
enum ValidationModuleState {
    case validating         // Processing validation
    case success            // Verification successful
    case needsReview        // Manual review required
    case rejected          // Verification rejected
    case error             // Validation error
}

// MARK: - Validation State Manager

/// Manages state for ValidationViewController following MVC pattern
/// This separates state management from the view controller
class ValidationState {
    
    // MARK: - State Properties
    
    var currentState: ValidationModuleState = .validating {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var status: String?
    var reason: String?
    var errorMessage: String?
    
    // MARK: - Callbacks
    
    var onStateChanged: ((ValidationModuleState) -> Void)?
    
    // MARK: - State Transitions
    
    func setSuccess(status: String) {
        self.status = status
        currentState = .success
    }
    
    func setNeedsReview(status: String, reason: String?) {
        self.status = status
        self.reason = reason
        currentState = .needsReview
    }
    
    func setRejected(status: String, reason: String?) {
        self.status = status
        self.reason = reason
        currentState = .rejected
    }
    
    func setError(_ message: String) {
        errorMessage = message
        currentState = .error
    }
    
    func retryValidation() {
        status = nil
        reason = nil
        errorMessage = nil
        currentState = .validating
    }
    
    func reset() {
        currentState = .validating
        status = nil
        reason = nil
        errorMessage = nil
    }
}
