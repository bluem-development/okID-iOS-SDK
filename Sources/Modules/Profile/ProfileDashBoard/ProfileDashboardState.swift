import Foundation

// MARK: - Profile Dashboard Module State

/// Represents the current state of the profile dashboard
enum ProfileDashboardModuleState {
    case checkingPin
    case pinRequired
    case loading
    case loaded
    case error(message: String)
}

// MARK: - Profile Dashboard State Manager

/// Manages state for ProfileDashboardViewController following MVC pattern
/// Separates state management from the view controller
class ProfileDashboardState {
    
    // MARK: - State Properties
    
    var currentState: ProfileDashboardModuleState = .checkingPin {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var profileStatus: OkIDProfileStatus = OkIDProfileStatus.empty {
        didSet {
            onProfileStatusChanged?(profileStatus)
        }
    }
    
    var isPinEnabled: Bool = false {
        didSet {
            onPinStateChanged?(isPinEnabled)
        }
    }
    
    var isPinVerified: Bool = false
    
    // MARK: - Callbacks
    
    var onStateChanged: ((ProfileDashboardModuleState) -> Void)?
    var onProfileStatusChanged: ((OkIDProfileStatus) -> Void)?
    var onPinStateChanged: ((Bool) -> Void)?
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        if case .loading = currentState { return true }
        if case .checkingPin = currentState { return true }
        return false
    }
    
    var hasProfile: Bool {
        return profileStatus.document != .none ||
               profileStatus.liveness != .none ||
               profileStatus.nfc != .none
    }
    
    // MARK: - State Transitions
    
    func startLoading() {
        currentState = .loading
    }
    
    func finishLoading(status: OkIDProfileStatus) {
        profileStatus = status
        currentState = .loaded
    }
    
    func requirePin() {
        currentState = .pinRequired
    }
    
    func pinVerified() {
        isPinVerified = true
    }
    
    func setError(_ message: String) {
        currentState = .error(message: message)
    }
    
    func reset() {
        currentState = .checkingPin
        profileStatus = OkIDProfileStatus.empty
        isPinEnabled = false
        isPinVerified = false
    }
}
