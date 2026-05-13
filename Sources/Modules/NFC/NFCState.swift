import Foundation

// MARK: - NFC Input State

/// State for the NFC input form screen
class NFCInputState {
    
    var isLoading: Bool = false {
        didSet { onStateChanged?() }
    }
    
    var onStateChanged: (() -> Void)?
}

// MARK: - NFC Reading Screen State

/// Represents the current state of the NFC reading screen flow
enum NFCReadingScreenState {
    case idle
    case reading(progress: Float, message: String)
    case completed
    case error(message: String)
    case unavailable
}

/// State for the NFC reading screen (named to avoid conflict with NFCReadingState in NFCModels)
class NFCReadingScreenController {
    
    var currentState: NFCReadingScreenState = .idle {
        didSet { onStateChanged?(currentState) }
    }
    
    var onStateChanged: ((NFCReadingScreenState) -> Void)?
    
    // MARK: - Computed Properties
    
    var isReading: Bool {
        if case .reading = currentState { return true }
        return false
    }
    
    var hasError: Bool {
        if case .error = currentState { return true }
        if case .unavailable = currentState { return true }
        return false
    }
    
    var hasCompleted: Bool {
        if case .completed = currentState { return true }
        return false
    }
    
    // MARK: - State Transitions
    
    func startReading() {
        currentState = .reading(progress: 0.1, message: "Hold passport near the top of your iPhone...")
    }
    
    func updateProgress(_ progress: Float, message: String) {
        currentState = .reading(progress: progress, message: message)
    }
    
    func complete() {
        currentState = .completed
    }
    
    func setError(_ message: String) {
        currentState = .error(message: message)
    }
    
    func setUnavailable() {
        currentState = .unavailable
    }
    
    func reset() {
        currentState = .idle
    }
}

// MARK: - MRZ Camera State

/// State for the MRZ camera scanning screen
class MrzCameraState {
    
    /// Frame throttle flag — NOT tied to UI spinner
    var isProcessing: Bool = false
    var hasCompleted: Bool = false
    /// Whether to show the processing spinner (only when completing)
    var showSpinner: Bool = false {
        didSet { onSpinnerChanged?(showSpinner) }
    }
    var statusMessage: String = "Align passport MRZ (bottom lines)" {
        didSet { onStatusChanged?(statusMessage) }
    }
    
    var onStatusChanged: ((String) -> Void)?
    var onSpinnerChanged: ((Bool) -> Void)?
    var onCompleted: ((OkIDPassportCredentials) -> Void)?
    
    func markCompleted() {
        hasCompleted = true
    }
    
    func reset() {
        isProcessing = false
        hasCompleted = false
        showSpinner = false
        statusMessage = "Align passport MRZ (bottom lines)"
    }
}
