import UIKit

/// Detection state for progressive user guidance
enum DetectionState: CustomStringConvertible {
    case searching       // No valid detections
    case detectedBadPosition // Has detections but not fully within guide area
    case detectedBlurry  // All within guide area but blurry
    case ready           // All conditions met
    
    var description: String {
        switch self {
        case .searching: return "searching"
        case .detectedBadPosition: return "detectedBadPosition"
        case .detectedBlurry: return "detectedBlurry"
        case .ready: return "ready"
        }
    }
}

/// Manages state for the document camera screen following MVC pattern
class DocumentCameraState {
    
    // MARK: - Detection State
    
    var detectionState: DetectionState = .searching {
        didSet {
            if oldValue != detectionState {
                onDetectionStateChanged?(detectionState)
            }
        }
    }
    
    var currentBlurScore: Double?
    var allValidDetections: [YOLODetection] = []
    var containedDetections: [YOLODetection] = []
    var clippedDetections: [YOLODetection] = []
    var maxConfidence: Float = 0.0
    
    // MARK: - Capture State
    
    var isCapturing = false {
        didSet { onCaptureStateChanged?(isCapturing) }
    }
    
    var autoCaptureFired = false
    var isCheckingQuality = false
    
    // MARK: - Validated Results
    
    var validatedImage: UIImage?
    var validatedBlurScore: Double?
    
    // MARK: - Guide Area
    
    var guideRect: CGRect?
    var fullCameraImageSize: CGSize?
    var croppedImageSize: CGSize?
    
    // MARK: - Callbacks
    
    var onDetectionStateChanged: ((DetectionState) -> Void)?
    var onCaptureStateChanged: ((Bool) -> Void)?
}
