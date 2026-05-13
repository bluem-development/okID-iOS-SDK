import Foundation
import UIKit
import CoreML
import Vision

private let logger = Logger.yolo

/// YOLO document detection configuration
struct YOLOConfig {
    static let confidenceThreshold: Float = 0.25  // 25% - initial detection
    static let requiredConfidenceThreshold: Float = 0.5  // 50% - for auto-capture
    static let iouThreshold: Float = 0.4
    static let edgeMarginPixels: CGFloat = 2.0
    static let validDocumentClasses = ["portrait", "idcard", "mrz", "passport"]
    
    static func isValidDocumentClass(_ className: String) -> Bool {
        return validDocumentClasses.contains(className.lowercased())
    }
}

/// YOLO detection result
struct YOLODetection {
    let boundingBox: CGRect
    let confidence: Float
    let className: String
}

/// Document detection state with YOLO results
struct DocumentDetectionResult {
    let allValidDetections: [YOLODetection]
    let containedDetections: [YOLODetection]
    let clippedDetections: [YOLODetection]
    let maxConfidence: Float
}

/// YOLO-based document detector
class YOLODocumentDetector {
    
    private var model: VNCoreMLModel?
    private let modelName = "document_detection_320"
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        logger.info("Attempting to load model...")
        
        if let compiledURL = Bundle.module.url(forResource: "document_detection_320", withExtension: "mlmodelc") {
            logger.info("Found compiled model at: \(compiledURL.path)")
            do {
                let mlModel = try MLModel(contentsOf: compiledURL)
                model = try VNCoreMLModel(for: mlModel)
                logger.info("✓ Compiled model loaded successfully")
                return
            } catch {
                logger.error("Failed to load compiled model: \(error)")
            }
        } else {
            logger.debug("Compiled model (.mlmodelc) not found")
        }
        
        // Try .mlpackage directly
        if let packageURL = Bundle.module.url(forResource: "yolo12n", withExtension: "mlpackage") {
            logger.info("Found mlpackage at: \(packageURL.path)")
            do {
                let mlModel = try MLModel(contentsOf: packageURL)
                model = try VNCoreMLModel(for: mlModel)
                logger.info("✓ MLPackage loaded successfully")
                return
            } catch {
                logger.error("Failed to load mlpackage: \(error)")
            }
        } else {
            logger.debug("MLPackage not found")
        }
        
        // Last resort: try without extension
        if let genericURL = Bundle.module.url(forResource: "yolo12n", withExtension: nil) {
            logger.info("Found model at: \(genericURL.path)")
            do {
                let mlModel = try MLModel(contentsOf: genericURL)
                model = try VNCoreMLModel(for: mlModel)
                logger.info("✓ Model loaded successfully")
                return
            } catch {
                logger.error("Failed to load model: \(error)")
            }
        }
        
        logger.error("❌ ERROR: Could not load model from any source")
        logger.error("Check that yolo12n.mlpackage exists in Sources/Resources/")
        logger.error("Check Package.swift includes: .process(\"Resources/yolo12n.mlpackage\")")
    }
    
    /// Run YOLO inference on image
    func detect(image: UIImage, completion: @escaping (DocumentDetectionResult?) -> Void) {
        logger.debug("detect() called with image size: \(image.size)")
        
        guard let model = model else {
            logger.error("Model not available - cannot detect")
            completion(nil)
            return
        }
        
        logger.debug("Model is available, creating CIImage...")
        
        guard let ciImage = CIImage(image: image) else {
            logger.error("Failed to create CIImage")
            completion(nil)
            return
        }
        
        logger.debug("Running inference...")
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            logger.debug("VNCoreMLRequest callback triggered")
            
            guard let self = self else {
                logger.error("Self was deallocated")
                return
            }
            
            if let error = error {
                logger.error("Prediction error: \(error)")
                completion(nil)
                return
            }
            
            logger.debug("Parsing results...")
            let result = self.parseResults(request: request, imageSize: image.size)
            logger.debug("Calling completion with result")
            completion(result)
        }
        
        // Set confidence threshold
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        logger.debug("Dispatching to background queue...")
        DispatchQueue.global(qos: .userInitiated).async {
            logger.debug("Background queue executing handler.perform...")
            do {
                try handler.perform([request])
                logger.debug("Handler.perform completed successfully")
            } catch {
                logger.error("Handler error: \(error)")
                completion(nil)
            }
        }
    }
    
    private func parseResults(request: VNRequest, imageSize: CGSize) -> DocumentDetectionResult {
        var allValidDetections: [YOLODetection] = []
        var containedDetections: [YOLODetection] = []
        var clippedDetections: [YOLODetection] = []
        var maxConfidence: Float = 0.0
        
        // Parse VNRecognizedObjectObservation results
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            logger.debug("No observations found")
            return DocumentDetectionResult(
                allValidDetections: [],
                containedDetections: [],
                clippedDetections: [],
                maxConfidence: 0.0
            )
        }
        
        logger.debug("Found \(observations.count) detections")
        
        for observation in observations {
            guard let topLabel = observation.labels.first else { continue }
            
            let className = topLabel.identifier.lowercased()
            let confidence = observation.confidence
            
            logger.debug("Detection: \(className) at \(String(format: "%.1f", confidence * 100))%")
            
            // Filter by confidence threshold
            guard confidence >= YOLOConfig.confidenceThreshold else {
                continue
            }
            
            // Only process valid document classes
            guard YOLOConfig.isValidDocumentClass(className) else {
                continue
            }
            
            // Convert normalized bounding box to image coordinates
            let boundingBox = convertBoundingBox(observation.boundingBox, imageSize: imageSize)
            
            let detection = YOLODetection(
                boundingBox: boundingBox,
                confidence: confidence,
                className: className
            )
            
            allValidDetections.append(detection)
            
            // Check if fully within guide area
            let isWithinGuide = isWithinGuideArea(boundingBox: boundingBox, imageSize: imageSize)
            
            if isWithinGuide {
                containedDetections.append(detection)
                logger.debug("✓ \(className) WITHIN GUIDE")
            } else {
                clippedDetections.append(detection)
                logger.debug("✗ \(className) OUTSIDE GUIDE")
            }
            
            // Track max confidence
            if confidence > maxConfidence {
                maxConfidence = confidence
            }
        }
        
        logger.debug("Summary - Total: \(allValidDetections.count), Contained: \(containedDetections.count), Clipped: \(clippedDetections.count)")
        
        return DocumentDetectionResult(
            allValidDetections: allValidDetections,
            containedDetections: containedDetections,
            clippedDetections: clippedDetections,
            maxConfidence: maxConfidence
        )
    }
    
    private func convertBoundingBox(_ normalizedBox: CGRect, imageSize: CGSize) -> CGRect {
        // Vision framework uses normalized coordinates with origin at bottom-left
        // Convert to top-left origin for consistency
        let x = normalizedBox.origin.x * imageSize.width
        let y = (1 - normalizedBox.origin.y - normalizedBox.height) * imageSize.height
        let width = normalizedBox.width * imageSize.width
        let height = normalizedBox.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func isWithinGuideArea(boundingBox: CGRect, imageSize: CGSize) -> Bool {
        let margin = YOLOConfig.edgeMarginPixels
        
        let leftOk = boundingBox.minX >= margin
        let rightOk = boundingBox.maxX <= (imageSize.width - margin)
        let topOk = boundingBox.minY >= margin
        let bottomOk = boundingBox.maxY <= (imageSize.height - margin)
        
        let allOk = leftOk && rightOk && topOk && bottomOk
        
        if !allOk {
            logger.debug("Bbox extends beyond guide - " +
                  "L:{\(Int(boundingBox.minX))} (min:\(Int(margin))) " +
                  "R:{\(Int(boundingBox.maxX))} (max:\(Int(imageSize.width - margin))) " +
                  "T:{\(Int(boundingBox.minY))} (min:\(Int(margin))) " +
                  "B:{\(Int(boundingBox.maxY))} (max:\(Int(imageSize.height - margin)))")
            logger.debug("Status - L:\(leftOk ? "✓" : "✗") R:\(rightOk ? "✓" : "✗") T:\(topOk ? "✓" : "✗") B:\(bottomOk ? "✓" : "✗")")
        }
        
        return allOk
    }
}

