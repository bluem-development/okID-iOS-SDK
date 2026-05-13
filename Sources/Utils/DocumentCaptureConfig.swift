import Foundation
import CoreGraphics

/// Configuration constants for document capture
struct DocumentCaptureConfig {
    
    // MARK: - YOLO Detection Thresholds
    
    /// Initial detection confidence threshold (25%)
    static let yoloConfidenceThreshold: Float = 0.25
    
    /// Required confidence for auto-capture (50%)
    static let requiredConfidenceThreshold: Float = 0.5
    
    /// IOU threshold for YOLO detection
    static let yoloIouThreshold: Float = 0.4
    
    // MARK: - Edge Containment
    
    /// Margin for YOLO detection tolerance (2 pixels)
    static let edgeMarginPixels: CGFloat = 2.0
    
    // MARK: - Guide Frame Dimensions
    
    /// Guide width as ratio of screen width (70%)
    static let guideWidthRatio: CGFloat = 0.6
    
    /// ID card aspect ratio (width/height = 1.6)
    static let guideAspectRatio: CGFloat = 1.6
    
    // MARK: - Auto-Capture Quality Check
    
    /// Quality check interval in milliseconds (1000ms = 1 second)
    static let qualityCheckIntervalMs: Int = 1000
    
    // MARK: - Visual Feedback Timing
    
    /// Flash effect duration in milliseconds
    static let flashEffectDurationMs: Int = 200
    
    /// Animation duration in milliseconds
    static let animationDurationMs: Int = 300
    
    // MARK: - Image Processing
    
    /// JPEG compression quality (95%)
    static let jpegQuality: CGFloat = 0.95
    
    /// Padding around detected document (5%)
    static let documentPadding: CGFloat = 0.05
    
    // MARK: - UI Layout
    
    /// Status indicator top offset from safe area
    static let statusIndicatorTopOffset: CGFloat = 80.0
    
    /// Capture button bottom offset from safe area
    static let captureButtonBottomOffset: CGFloat = 40.0
    
    /// Capture button size (diameter)
    static let captureButtonSize: CGFloat = 70.0
    
    /// Capture button border width
    static let captureButtonBorderWidth: CGFloat = 4.0
    
    // MARK: - Detection Update Throttling
    
    /// Detection update throttle in milliseconds
    static let detectionUpdateThrottleMs: Int = 500
    
    // MARK: - Debug Visualization
    
    /// Enable debug bounding boxes in DEBUG builds
    #if DEBUG
    static let enableDebugBoundingBoxes: Bool = true
    #else
    static let enableDebugBoundingBoxes: Bool = false
    #endif
    
    // MARK: - Class Name Filters
    
    /// Valid document classes for YOLO detection
    static let validDocumentClasses: Set<String> = ["portrait", "idcard", "mrz", "passport"]
    
    /// Check if a class name is a valid document class
    /// - Parameter className: The class name to check
    /// - Returns: True if the class is valid for document detection
    static func isValidDocumentClass(_ className: String) -> Bool {
        return validDocumentClasses.contains(className.lowercased())
    }
}
