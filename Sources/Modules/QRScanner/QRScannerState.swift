import Foundation

// MARK: - QR Scanner Module State

/// Represents the current state of the QR scanner flow
enum QRScannerModuleState {
    case scanning
    case found(result: OkIDQRScanResult)
    case error(message: String)
    case failed  // device doesn't support scanning
}

// MARK: - QR Scanner State Manager

/// Manages state for QRScannerViewController following MVC pattern
/// Separates state management from the view controller
class QRScannerState {
    
    // MARK: - State Properties
    
    var currentState: QRScannerModuleState = .scanning {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var isTorchOn: Bool = false {
        didSet {
            onTorchChanged?(isTorchOn)
        }
    }
    
    // MARK: - Callbacks
    
    var onStateChanged: ((QRScannerModuleState) -> Void)?
    var onTorchChanged: ((Bool) -> Void)?
    
    // MARK: - Computed Properties
    
    var isScanning: Bool {
        if case .scanning = currentState { return true }
        return false
    }
    
    // MARK: - State Transitions
    
    func codeFound(_ result: OkIDQRScanResult) {
        currentState = .found(result: result)
    }
    
    func setError(_ message: String) {
        currentState = .error(message: message)
    }
    
    func setFailed() {
        currentState = .failed
    }
    
    func resumeScanning() {
        currentState = .scanning
    }
    
    func toggleTorch() {
        isTorchOn.toggle()
    }
    
    func reset() {
        currentState = .scanning
        isTorchOn = false
    }
}
