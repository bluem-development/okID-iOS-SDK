import Foundation

/// Result of a PIN completion attempt
enum PinCompletionResult {
    case flowComplete       // PIN accepted, flow is done
    case nextStep           // Move to next step in multi-step flow
    case error(String)      // Error with message
}

/// Business logic for PIN flow following MVC pattern
/// Handles: flow state management, PIN validation, storage
class PinFlowManager {
    
    // MARK: - Properties
    
    let flowType: PinFlowType
    private(set) var currentStep: Int = 0
    private var tempPin: String?
    
    // MARK: - Initialization
    
    init(flowType: PinFlowType) {
        self.flowType = flowType
    }
    
    // MARK: - Title / Subtitle
    
    func getTitleForMode() -> String {
        switch flowType {
        case .verify:
            return "Enter PIN"
        case .disable:
            return "Enter PIN"
        case .setup:
            return currentStep == 0 ? "Create PIN" : "Confirm PIN"
        case .change:
            switch currentStep {
            case 0: return "Current PIN"
            case 1: return "Create PIN"
            case 2: return "Confirm PIN"
            default: return "PIN"
            }
        }
    }
    
    func getSubtitleForMode() -> String {
        switch flowType {
        case .verify:
            return "Enter your PIN to access Identity Vault"
        case .disable:
            return "Enter your PIN to disable protection"
        case .setup:
            return currentStep == 0 ? "Create a 4-digit PIN to protect your Identity Vault" : "Re-enter your PIN to confirm"
        case .change:
            switch currentStep {
            case 0: return "Enter your current PIN"
            case 1: return "Create a new 4-digit PIN"
            case 2: return "Re-enter your new PIN to confirm"
            default: return ""
            }
        }
    }
    
    /// Whether the "Forgot PIN" button should be shown
    func shouldShowForgotButton() -> Bool {
        return flowType == .verify || flowType == .disable || (flowType == .change && currentStep == 0)
    }
    
    // MARK: - PIN Completion Handler
    
    /// Handle completed PIN entry. Returns result asynchronously.
    func handlePinComplete(_ enteredPin: String) async -> PinCompletionResult {
        switch flowType {
        case .verify, .disable:
            let isValid = await PinManager.verifyPin(enteredPin)
            if isValid {
                return .flowComplete
            } else {
                return .error("Incorrect PIN")
            }
            
        case .setup:
            if currentStep == 0 {
                tempPin = enteredPin
                return .nextStep
            } else {
                if enteredPin == tempPin {
                    try? await PinManager.setPin(enteredPin)
                    return .flowComplete
                } else {
                    return .error("PINs do not match")
                }
            }
            
        case .change:
            switch currentStep {
            case 0:
                let isValid = await PinManager.verifyPin(enteredPin)
                if isValid {
                    return .nextStep
                } else {
                    return .error("Incorrect PIN")
                }
            case 1:
                tempPin = enteredPin
                return .nextStep
            case 2:
                if enteredPin == tempPin {
                    try? await PinManager.setPin(enteredPin)
                    return .flowComplete
                } else {
                    return .error("PINs do not match")
                }
            default:
                return .error("Invalid step")
            }
        }
    }
    
    // MARK: - Step Navigation
    
    /// Advance to next step
    func advanceStep() {
        currentStep += 1
    }
    
    /// Go back to previous step
    func goBack() {
        currentStep -= 1
        if currentStep == 0 {
            tempPin = nil
        }
    }
    
    /// Whether we can go back
    var canGoBack: Bool {
        return currentStep > 0
    }
    
    // MARK: - Forgot PIN
    
    /// Delete the PIN (for forgot flow)
    func deletePinAndReset() async {
        try? await PinManager.deletePin()
    }
}
