import Foundation
import UIKit

// MARK: - Liveness Module State

/// Represents the current state of the liveness capture flow
enum LivenessModuleState {
    case initial
    case capturing
    case uploading
    case error
}

// MARK: - Liveness State Manager

/// Manages state for LivenessViewController following MVC pattern
/// This separates state management from the view controller
class LivenessState {
    
    // MARK: - State Properties
    
    var currentState: LivenessModuleState = .capturing {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var capturedImage: Data? {
        didSet {
            onImageCaptured?(capturedImage)
        }
    }
    
    var biometricData: [String: Any]?
    
    var errorMessage: String? {
        didSet {
            if let error = errorMessage {
                onError?(error)
            }
        }
    }
    
    var shouldHideStatusBar: Bool = false {
        didSet {
            onStatusBarVisibilityChanged?(shouldHideStatusBar)
        }
    }
    
    // MARK: - Callbacks
    
    var onStateChanged: ((LivenessModuleState) -> Void)?
    var onImageCaptured: ((Data?) -> Void)?
    var onError: ((String) -> Void)?
    var onStatusBarVisibilityChanged: ((Bool) -> Void)?
    
    // MARK: - State Transitions
    
    func captureImage(_ imageData: Data, biometrics: [String: Any]?) {
        capturedImage = imageData
        biometricData = biometrics
        currentState = .uploading
    }
    
    func retryCapture() {
        capturedImage = nil
        biometricData = nil
        errorMessage = nil
        currentState = .capturing
    }
    
    func setError(_ message: String) {
        errorMessage = message
        currentState = .error
    }
    
    func reset() {
        currentState = .capturing
        capturedImage = nil
        biometricData = nil
        errorMessage = nil
        shouldHideStatusBar = false
    }
}
