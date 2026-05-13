import Foundation

// MARK: - Terms Module State

/// Represents the current state of the terms acceptance flow
enum TermsModuleState {
    case idle
    case submitting
    case accepted(nextStep: String?)
    case error(message: String)
}

// MARK: - Terms State Manager

/// Manages state for TermsViewController following MVC pattern
/// Separates state management from the view controller
class TermsState {
    
    // MARK: - State Properties
    
    var currentState: TermsModuleState = .idle {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var isAccepted: Bool = false {
        didSet {
            onAcceptanceChanged?(isAccepted)
        }
    }
    
    // MARK: - Callbacks
    
    var onStateChanged: ((TermsModuleState) -> Void)?
    var onAcceptanceChanged: ((Bool) -> Void)?
    
    // MARK: - Computed Properties
    
    var isSubmitting: Bool {
        if case .submitting = currentState { return true }
        return false
    }
    
    // MARK: - State Transitions
    
    func toggleAcceptance() {
        guard !isSubmitting else { return }
        isAccepted.toggle()
    }
    
    func startSubmitting() {
        currentState = .submitting
    }
    
    func completeAcceptance(nextStep: String?) {
        currentState = .accepted(nextStep: nextStep)
    }
    
    func setError(_ message: String) {
        currentState = .error(message: message)
    }
    
    func clearError() {
        if case .error = currentState {
            currentState = .idle
        }
    }
    
    func reset() {
        currentState = .idle
        isAccepted = false
    }
}
