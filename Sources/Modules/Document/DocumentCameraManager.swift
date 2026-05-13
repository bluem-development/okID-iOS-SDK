import UIKit
import AVFoundation
import AudioToolbox

private let logger = Logger.camera

/// Business logic for document camera capture following MVC pattern
/// Handles: detection state calculation, status messages, image cropping, auto-capture evaluation
class DocumentCameraManager {
    
    // MARK: - Properties
    
    private let qualityThreshold: Double
    let yoloDetector: YOLODocumentDetector?
    
    // MARK: - Initialization
    
    init(qualityThreshold: Double) {
        self.qualityThreshold = qualityThreshold
        self.yoloDetector = YOLODocumentDetector()
    }
    
    // MARK: - Detection State Calculation
    
    /// Calculate detection state from current state properties
    func calculateDetectionState(state: DocumentCameraState) -> DetectionState {
        // No detections
        if state.allValidDetections.isEmpty {
            logger.debug("→ SEARCHING (no detections)")
            return .searching
        }
        
        // Has detections but not fully within guide area
        if !state.clippedDetections.isEmpty {
            logger.debug("→ BAD_POSITION (\(state.clippedDetections.count) detections outside guide area)")
            return .detectedBadPosition
        }
        
        // All within guide area but blurry
        if (state.currentBlurScore ?? 0) < qualityThreshold {
            let score = state.currentBlurScore ?? 0
            logger.debug("→ BLURRY (score \(String(format: "%.2f", score)) < \(qualityThreshold))")
            return .detectedBlurry
        }
        
        // All conditions met
        logger.debug("→ READY (all conditions met!)")
        return .ready
    }
    
    // MARK: - Status Messages
    
    /// Get status message based on current state
    func getStatusMessage(state: DocumentCameraState) -> String {
        if state.isCapturing {
            return "Capturing..."
        }
        
        if state.autoCaptureFired {
            return "Processing capture..."
        }
        
        switch state.detectionState {
        case .searching:
            return "Point camera at document"
            
        case .detectedBadPosition:
            return "Fit entire document in frame"
            
        case .detectedBlurry:
            return getBlurryFeedback(score: state.currentBlurScore ?? 0)
            
        case .ready:
            return "Perfect! Hold still..."
        }
    }
    
    /// Get detailed blurry feedback
    func getBlurryFeedback(score: Double) -> String {
        let threshold = qualityThreshold
        
        // Very blurry - likely motion blur or very out of focus
        if score < threshold * 0.3 {
            return "Image too blurry - hold steady"
        }
        
        // Moderately blurry - close but needs improvement
        if score < threshold * 0.6 {
            return "Slightly blurry - ensure good lighting"
        }
        
        // Almost there - just needs minor adjustment
        return "Almost sharp - hold still"
    }
    
    // MARK: - Auto-Capture Evaluation
    
    /// Check if conditions are met for auto-capture
    func isReadyForAutoCapture(state: DocumentCameraState) -> Bool {
        return state.detectionState == .ready &&
               state.maxConfidence >= YOLOConfig.requiredConfidenceThreshold &&
               !state.containedDetections.isEmpty &&
               state.clippedDetections.isEmpty
    }
    
    // MARK: - Capture Button State
    
    /// Determine if capture button should be enabled
    func isCaptureEnabled(state: DocumentCameraState) -> Bool {
        return !state.isCapturing && (state.currentBlurScore ?? 0) >= qualityThreshold
    }
    
    /// Get capture button appearance based on state
    func getCaptureButtonAppearance(state: DocumentCameraState) -> (backgroundColor: UIColor, tintColor: UIColor, iconAlpha: CGFloat) {
        if state.isCapturing {
            return (.gray, .black, 0)
        }
        
        let isEnabled = isCaptureEnabled(state: state)
        if !isEnabled {
            return (UIColor.white.withAlphaComponent(0.5), UIColor.black.withAlphaComponent(0.3), 1)
        }
        
        if state.detectionState == .ready || state.detectionState == .detectedBlurry {
            return (.okidSuccess, .white, 1) // Green
        }
        
        return (.white, .black, 1)
    }
    
    // MARK: - Image Processing
    
    /// Crop image to guide area (matching reference copyCrop)
    func cropImageToGuideArea(image: UIImage, guideRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let cropRect = CGRect(
            x: guideRect.origin.x,
            y: guideRect.origin.y,
            width: guideRect.size.width,
            height: guideRect.size.height
        )
        
        logger.debug("Cropping image: from \(Int(image.size.width))x\(Int(image.size.height)) to rect(\(Int(cropRect.origin.x)), \(Int(cropRect.origin.y)), \(Int(cropRect.size.width))x\(Int(cropRect.size.height)))")
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            logger.error("Failed to crop CGImage")
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Calculate guide rectangle based on image dimensions
    func calculateGuideRect(imageSize: CGSize) -> CGRect {
        let guideWidth = imageSize.width * DocumentCaptureConfig.guideWidthRatio
        let guideHeight = guideWidth / DocumentCaptureConfig.guideAspectRatio
        let guideX = (imageSize.width - guideWidth) / 2
        let guideY = (imageSize.height - guideHeight) / 2
        return CGRect(x: guideY, y: guideX, width: guideHeight, height: guideWidth)
    }
    
    // MARK: - Silent Capture
    
    /// Execute a capture block with suppressed shutter sound
    func silentCapture(captureBlock: @escaping () -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        let currentCategory = audioSession.category
        let currentOptions = audioSession.categoryOptions
        
        do {
            try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try audioSession.setActive(true)
            
            captureBlock()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try audioSession.setCategory(currentCategory, options: currentOptions)
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    let okidError = OkIDErrorHandler.shared.normalize(error)
                    OkIDErrorHandler.shared.handle(
                        error,
                        context: "DocumentCameraManager.restoreAudioSession",
                        severity: .warning
                    )
                    logger.error("Failed to restore audio session: \(okidError.errorDescription ?? error.localizedDescription)")
                }
            }
        } catch {
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(
                error,
                context: "DocumentCameraManager.configureSilentCapture",
                severity: .warning
            )
            logger.error("Failed to configure silent capture: \(okidError.errorDescription ?? error.localizedDescription)")
            // Fallback: capture with sound
            captureBlock()
        }
    }
    
    // MARK: - Quality Check Processing
    
    /// Process a quality check image: crop, detect, calculate blur
    func processQualityCheck(
        imageData: Data,
        state: DocumentCameraState,
        completion: @escaping (Double, DetectionState, Bool) -> Void
    ) {
        guard let fullImage = UIImage(data: imageData) else {
            logger.error("Failed to capture quality check image")
            completion(0, .searching, false)
            return
        }
        
        // Calculate guide rectangle if needed
        if state.guideRect == nil {
            state.guideRect = calculateGuideRect(imageSize: fullImage.size)
            logger.debug("Guide rect calculated from image: \(Int(state.guideRect!.origin.x)), \(Int(state.guideRect!.origin.y)), \(Int(state.guideRect!.width))x\(Int(state.guideRect!.height))")
        }
        
        state.fullCameraImageSize = fullImage.size
        
        // Crop to guide area IMMEDIATELY for performance
        guard let croppedImage = cropImageToGuideArea(image: fullImage, guideRect: state.guideRect!) else {
            logger.error("Failed to crop image to guide area")
            completion(0, .searching, false)
            return
        }
        
        state.croppedImageSize = croppedImage.size
        
        logger.debug("Processing guide area only: \(Int(croppedImage.size.width))x\(Int(croppedImage.size.height)) (vs full \(Int(fullImage.size.width))x\(Int(fullImage.size.height)))")
        
        // Run YOLO inference for document detection
        yoloDetector?.detect(image: croppedImage) { [weak self] result in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    state.allValidDetections = result.allValidDetections
                    state.containedDetections = result.containedDetections
                    state.clippedDetections = result.clippedDetections
                    state.maxConfidence = result.maxConfidence
                }
            }
            
            // Calculate blur score on cropped image
            let blurScore = BlurDetection.calculateBlurScore(image: croppedImage)
            
            DispatchQueue.main.async {
                state.currentBlurScore = blurScore
                state.validatedBlurScore = blurScore
                
                // Update detection state
                state.detectionState = self.calculateDetectionState(state: state)
                
                logger.debug("Current: \(state.detectionState) | Blur: \(String(format: "%.2f", blurScore)) (threshold: \(self.qualityThreshold))")
                
                let readyForCapture = self.isReadyForAutoCapture(state: state)
                
                logger.debug("State: \(state.detectionState), Confidence: \(String(format: "%.1f", state.maxConfidence * 100))%, Blur: \(String(format: "%.2f", blurScore))")
                logger.debug("Ready: \(readyForCapture) (Properly positioned: \(state.containedDetections.count), Bad position: \(state.clippedDetections.count))")
                
                if readyForCapture {
                    logger.debug("All conditions met! Triggering auto-capture...")
                    state.autoCaptureFired = true
                    state.validatedImage = croppedImage
                }
                
                completion(blurScore, state.detectionState, readyForCapture)
            }
        }
    }
    
    // MARK: - Final Image Processing
    
    /// Process the final captured image for submission
    func processFinalImage(
        photo: AVCapturePhoto?,
        state: DocumentCameraState
    ) -> (image: UIImage, blurScore: Double, qualityTip: String?)? {
        
        let finalImage: UIImage
        
        if state.autoCaptureFired, let validated = state.validatedImage {
            logger.debug("Using pre-validated guide area frame for auto-capture")
            finalImage = validated
        } else {
            guard let photo = photo,
                  let imageData = photo.fileDataRepresentation(),
                  let fullImage = UIImage(data: imageData) else {
                logger.error("Failed to capture image")
                return nil
            }
            
            logger.debug("Captured \(imageData.count) bytes")
            
            // Calculate guide rectangle if not already done
            if state.guideRect == nil {
                state.guideRect = calculateGuideRect(imageSize: fullImage.size)
                logger.debug("Guide rect calculated for image: \(state.guideRect!)")
            }
            
            guard let croppedImage = cropImageToGuideArea(image: fullImage, guideRect: state.guideRect!) else {
                logger.error("Failed to crop image to guide area")
                return nil
            }
            
            logger.debug("Cropped to guide area: \(Int(croppedImage.size.width))x\(Int(croppedImage.size.height))")
            finalImage = croppedImage
        }
        
        // Calculate blur score
        let blurScore: Double
        if state.autoCaptureFired, let validated = state.validatedBlurScore {
            blurScore = validated
            logger.debug("Using pre-validated blur score: \(String(format: "%.2f", blurScore))")
        } else {
            blurScore = BlurDetection.calculateBlurScore(image: finalImage)
            logger.debug("Calculated blur score: \(String(format: "%.2f", blurScore))")
            
            // Check quality for manual capture
            if blurScore < qualityThreshold {
                let tip = blurScore < qualityThreshold * 0.5
                    ? "Try better lighting or clean lens"
                    : "Hold phone more steady"
                return (finalImage, blurScore, "Image not sharp enough. \(tip).")
            }
        }
        
        // Encode cropped image to JPEG
        guard let jpegData = finalImage.jpegData(compressionQuality: 0.95) else {
            logger.error("Failed to encode image")
            return nil
        }
        
        logger.debug("Quality check passed: \(String(format: "%.2f", blurScore)) >= \(qualityThreshold)")
        logger.debug("Final JPEG size: \(jpegData.count) bytes")
        
        return (finalImage, blurScore, nil)
    }
}
