import Foundation
import UIKit

// MARK: - Verification Flow State

/// Manages all mutable state for the verification flow
/// Separates state from the controller with observable callbacks
class VerificationFlowState {
    
    // MARK: - Flow State
    
    var isLoading: Bool = true {
        didSet { onUIUpdateNeeded?() }
    }
    
    var currentModule: String? {
        didSet { onUIUpdateNeeded?() }
    }
    
    var flow: [String] = []
    var modules: [String: Any] = [:]
    var moduleProgress: [String: String] = [:]
    
    var errorMessage: String? {
        didSet { onUIUpdateNeeded?() }
    }
    
    // MARK: - Profile State
    
    var profile: OkIDVerificationProfile?
    var profileStatus: OkIDProfileStatus?
    
    // MARK: - Auto-Submit State
    
    var isAutoSubmitting: Bool = false {
        didSet { onUIUpdateNeeded?() }
    }
    
    var autoSubmitMessage: String?
    
    // MARK: - Completion Tracking
    
    var hasCompletedOrCancelled: Bool = false
    
    // MARK: - Callbacks
    
    var onUIUpdateNeeded: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var shouldShowLoading: Bool {
        return isLoading
    }
    
    var shouldShowError: Bool {
        return !isLoading && errorMessage != nil
    }
    
    var shouldShowAutoSubmit: Bool {
        return !isLoading && errorMessage == nil && isAutoSubmitting
    }
    
    var shouldShowModule: Bool {
        return !isLoading && errorMessage == nil && !isAutoSubmitting
    }
}
