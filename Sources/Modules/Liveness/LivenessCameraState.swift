import Foundation
import UIKit

// MARK: - Capture Flow State Machine

/// Capture flow state machine (matches the reference `CaptureState` enum)
enum CaptureState {
    case detectingFace         // Looking for any face
    case faceFound             // Face detected but not properly positioned
    case readyForCapture       // Face looking straight, can start countdown
    case delayBeforeCountdown  // 3-second delay before countdown starts
    case countdown             // Countdown in progress
    case capturing             // Taking picture
}

// MARK: - Age/Gender Reading

/// Age/gender reading collected during countdown
struct AgeGenderReading {
    let age: Double
    let gender: String
    let confidence: Double
    let timestamp: Date
}

// MARK: - Liveness Camera State

/// State for the liveness camera screen
/// Separates all mutable state from the controller with observable callbacks
class LivenessCameraState {
    
    // MARK: - State Machine
    
    var captureState: CaptureState = .detectingFace {
        didSet { onCaptureStateChanged?(captureState) }
    }
    
    var statusMessage: String = "Position your face in the oval" {
        didSet { onStatusMessageChanged?(statusMessage) }
    }
    
    // MARK: - Countdown
    
    var countdownRemaining: Int = 3 {
        didSet { onCountdownChanged?(countdownRemaining) }
    }
    
    var delayRemaining: Int = 0
    
    // MARK: - Face Detection Flags
    
    var isProcessingFrame: Bool = false
    var isProcessingBiometric: Bool = false
    var isCameraCapturing: Bool = false
    var isInitialized: Bool = false
    var isDisposing: Bool = false
    
    var lastDetectedFace: FaceDetectionResult?
    
    // MARK: - Biometric Data
    
    var biometricReadings: [AgeGenderReading] = []
    var currentBiometricDisplay: AgeGenderReading? {
        didSet { onBiometricDisplayChanged?(currentBiometricDisplay) }
    }
    
    // MARK: - Callbacks
    
    var onCaptureStateChanged: ((CaptureState) -> Void)?
    var onStatusMessageChanged: ((String) -> Void)?
    var onCountdownChanged: ((Int) -> Void)?
    var onBiometricDisplayChanged: ((AgeGenderReading?) -> Void)?
    var onUIUpdateNeeded: (() -> Void)?
    var onCountdownVisibilityChanged: ((Bool) -> Void)?
    var onStartCountdownDisplay: (() -> Void)?
    var onCaptureTriggered: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Get overlay color based on current state
    var overlayColor: UIColor {
        switch captureState {
        case .detectingFace:
            return UIColor.white.withAlphaComponent(0.5)
        case .faceFound:
            return .orange
        case .readyForCapture, .delayBeforeCountdown, .countdown:
            return .green
        case .capturing:
            return .green
        }
    }
    
    /// Whether the state indicator badge should be visible
    var shouldShowStateIndicator: Bool {
        return captureState == .detectingFace || captureState == .faceFound
    }
    
    /// State indicator info (icon, color, text) for current state
    var stateIndicatorInfo: (icon: String, color: UIColor, text: String)? {
        switch captureState {
        case .detectingFace:
            return ("magnifyingglass", .white, "Looking for face...")
        case .faceFound:
            return ("arrow.left.and.right", .orange, "Adjust position")
        default:
            return nil
        }
    }
    
    // MARK: - State Transitions
    
    func reset() {
        captureState = .detectingFace
        statusMessage = "Position your face in the oval"
        countdownRemaining = 3
        delayRemaining = 0
        isProcessingFrame = false
        isProcessingBiometric = false
        isCameraCapturing = false
        lastDetectedFace = nil
        biometricReadings.removeAll()
        currentBiometricDisplay = nil
    }
}
