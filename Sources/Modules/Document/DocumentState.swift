import Foundation
import UIKit

// MARK: - Document Module State

/// Represents the current state of the document capture flow
enum DocumentModuleState {
    case initial
    case capturing
    case previewing
    case uploading
    case nfcMrzScan
    case nfcReading
    case error
}

// MARK: - Document State Manager

/// Manages state for DocumentViewController following MVC pattern
/// This separates state management from the view controller
class DocumentState {
    
    // MARK: - State Properties
    
    var currentState: DocumentModuleState = .initial {
        didSet {
            onStateChanged?(currentState)
        }
    }
    
    var currentSide: String = "front" {
        didSet {
            onSideChanged?(currentSide)
        }
    }
    
    var capturedFrontImage: Data?
    var capturedBackImage: Data?
    var frontBlurScore: Double?
    var backBlurScore: Double?
    
    var errorMessage: String? {
        didSet {
            if let error = errorMessage {
                onError?(error)
            }
        }
    }
    
    // MARK: - NFC State
    
    var pendingNextStep: String?
    var nfcCredentials: OkIDPassportCredentials?
    var nfcReadStartTime: Date?
    var usedPace: Bool = true
    var nfcChecked: Bool = false
    var nfcAvailability: Bool = false
    
    // MARK: - Callbacks
    
    var onStateChanged: ((DocumentModuleState) -> Void)?
    var onSideChanged: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Computed Properties
    
    var hasCapturedCurrentSide: Bool {
        return currentSide == "front" ? capturedFrontImage != nil : capturedBackImage != nil
    }
    
    var currentBlurScore: Double? {
        return currentSide == "front" ? frontBlurScore : backBlurScore
    }
    
    var needsBackSide: Bool {
        return capturedFrontImage != nil && capturedBackImage == nil
    }
    
    // MARK: - State Transitions
    
    func captureImage(_ imageData: Data, blurScore: Double) {
        if currentSide == "front" {
            capturedFrontImage = imageData
            frontBlurScore = blurScore
        } else {
            capturedBackImage = imageData
            backBlurScore = blurScore
        }
        currentState = .previewing
    }
    
    func retakeImage() {
        if currentSide == "front" {
            capturedFrontImage = nil
            frontBlurScore = nil
        } else {
            capturedBackImage = nil
            backBlurScore = nil
        }
        currentState = .capturing  // Go directly to camera
    }
    
    func confirmAndProceed(requiresBackSide: Bool) {
        if currentSide == "front" && requiresBackSide {
            currentSide = "back"
            currentState = .initial
        } else {
            currentState = .uploading
        }
    }
    
    func reset() {
        currentState = .initial
        currentSide = "front"
        capturedFrontImage = nil
        capturedBackImage = nil
        frontBlurScore = nil
        backBlurScore = nil
        errorMessage = nil
        pendingNextStep = nil
        nfcCredentials = nil
        nfcReadStartTime = nil
    }
}
