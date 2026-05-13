import Foundation
import UIKit
import Vision

private let logger = Logger.document

/// Document quality analysis result
public struct DocumentQualityResult {
    public let blurScore: Double
    public let isBlurry: Bool
    public let isCentered: Bool
    public let hasGoodSize: Bool
    public let hasGlare: Bool
    public let confidence: Double
    
    public var isGoodQuality: Bool {
        !isBlurry && isCentered && hasGoodSize && !hasGlare
    }
    
    public var qualityDescription: String {
        if isGoodQuality {
            return "Excellent quality"
        }
        
        var issues: [String] = []
        if isBlurry { issues.append("Image is blurry") }
        if !isCentered { issues.append("Document not centered") }
        if !hasGoodSize { issues.append("Document too small") }
        if hasGlare { issues.append("Glare detected") }
        
        return issues.joined(separator: ", ")
    }
    
    public init(
        blurScore: Double,
        isBlurry: Bool,
        isCentered: Bool,
        hasGoodSize: Bool,
        hasGlare: Bool,
        confidence: Double
    ) {
        self.blurScore = blurScore
        self.isBlurry = isBlurry
        self.isCentered = isCentered
        self.hasGoodSize = hasGoodSize
        self.hasGlare = hasGlare
        self.confidence = confidence
    }
}

/// 2D Point
public struct DocumentPoint {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

/// Document boundaries/corners in image
public struct DocumentBoundaries {
    public let topLeft: DocumentPoint
    public let topRight: DocumentPoint
    public let bottomRight: DocumentPoint
    public let bottomLeft: DocumentPoint
    public let confidence: Double
    
    public init(
        topLeft: DocumentPoint,
        topRight: DocumentPoint,
        bottomRight: DocumentPoint,
        bottomLeft: DocumentPoint,
        confidence: Double
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.confidence = confidence
    }
    
    /// Get center point of document
    public var center: DocumentPoint {
        let centerX = (topLeft.x + topRight.x + bottomRight.x + bottomLeft.x) / 4
        let centerY = (topLeft.y + topRight.y + bottomRight.y + bottomLeft.y) / 4
        return DocumentPoint(x: centerX, y: centerY)
    }
    
    /// Calculate document area using Shoelace formula
    public var area: Double {
        let sum1 = topLeft.x * topRight.y - topRight.x * topLeft.y
        let sum2 = topRight.x * bottomRight.y - bottomRight.x * topRight.y
        let sum3 = bottomRight.x * bottomLeft.y - bottomLeft.x * bottomRight.y
        let sum4 = bottomLeft.x * topLeft.y - topLeft.x * bottomLeft.y
        
        return abs(sum1 + sum2 + sum3 + sum4) / 2.0
    }
}

/// Document processing service for quality validation
public class DocumentProcessor {
    
    public static let shared = DocumentProcessor()
    
    private var isInitialized = false
    
    /// Blur threshold (higher = sharper)
    public var blurThreshold: Double = 150.0
    
    /// Minimum document area ratio (document area / image area)
    public var minAreaRatio: Double = 0.3
    
    /// Maximum document area ratio
    public var maxAreaRatio: Double = 0.9
    
    /// Glare threshold (0-255, higher = more glare tolerance)
    public var glareThreshold: Double = 240.0
    
    private init() {}
    
    /// Initialize the document processor
    public func initialize() async {
        guard !isInitialized else { return }
        
        // In production, you would load ML models here (e.g., YOLO for document detection)
        // For now, we use Vision framework's rectangle detection
        
        isInitialized = true
        logger.info("Initialized successfully")
    }
    
    /// Process document image and return quality metrics
    /// - Parameter image: The document image to analyze
    /// - Returns: Quality analysis result
    public func processDocument(image: UIImage) async throws -> DocumentQualityResult {
        if !isInitialized {
            await initialize()
        }
        
        // Calculate blur score
        let blurScore = BlurDetection.calculateBlurScore(image: image)
        let isBlurry = blurScore < blurThreshold
        
        // Detect document boundaries
        let boundaries = try await detectDocumentBoundaries(image: image)
        
        // Check if centered
        let isCentered = boundaries != nil ? isDocumentCentered(
            boundaries: boundaries!,
            imageSize: image.size
        ) : true
        
        // Check size
        let hasGoodSize = boundaries != nil ? self.hasGoodSize(
            boundaries: boundaries!,
            imageSize: image.size
        ) : true
        
        // Check for glare
        let hasGlare = try await self.hasGlare(image: image)
        
        return DocumentQualityResult(
            blurScore: blurScore,
            isBlurry: isBlurry,
            isCentered: isCentered,
            hasGoodSize: hasGoodSize,
            hasGlare: hasGlare,
            confidence: boundaries?.confidence ?? 0.0
        )
    }
    
    /// Detect document boundaries in image using Vision framework
    /// - Parameter image: The image to analyze
    /// - Returns: Document boundaries or nil if not detected
    public func detectDocumentBoundaries(image: UIImage) async throws -> DocumentBoundaries? {
        guard let cgImage = image.cgImage else {
            throw DocumentProcessorError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      let rectangle = observations.first else {
                    // No rectangle detected, return full image bounds
                    let width = Double(image.size.width)
                    let height = Double(image.size.height)
                    let boundaries = DocumentBoundaries(
                        topLeft: DocumentPoint(x: 0, y: 0),
                        topRight: DocumentPoint(x: width, y: 0),
                        bottomRight: DocumentPoint(x: width, y: height),
                        bottomLeft: DocumentPoint(x: 0, y: height),
                        confidence: 0.0
                    )
                    continuation.resume(returning: boundaries)
                    return
                }
                
                // Convert normalized coordinates to image coordinates
                let width = Double(image.size.width)
                let height = Double(image.size.height)
                
                let boundaries = DocumentBoundaries(
                    topLeft: DocumentPoint(
                        x: Double(rectangle.topLeft.x) * width,
                        y: Double(1 - rectangle.topLeft.y) * height
                    ),
                    topRight: DocumentPoint(
                        x: Double(rectangle.topRight.x) * width,
                        y: Double(1 - rectangle.topRight.y) * height
                    ),
                    bottomRight: DocumentPoint(
                        x: Double(rectangle.bottomRight.x) * width,
                        y: Double(1 - rectangle.bottomRight.y) * height
                    ),
                    bottomLeft: DocumentPoint(
                        x: Double(rectangle.bottomLeft.x) * width,
                        y: Double(1 - rectangle.bottomLeft.y) * height
                    ),
                    confidence: Double(rectangle.confidence)
                )
                
                continuation.resume(returning: boundaries)
            }
            
            // Configure request
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 2.0
            request.minimumSize = 0.2
            request.maximumObservations = 1
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Check if document has glare/reflections
    /// - Parameter image: The image to analyze
    /// - Returns: True if glare is detected
    public func hasGlare(image: UIImage) async throws -> Bool {
        guard let cgImage = image.cgImage else {
            throw DocumentProcessorError.invalidImage
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Count pixels above glare threshold
        var glarePixelCount = 0
        let totalPixels = width * height
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            
            let brightness = (r + g + b) / 3.0
            
            if brightness > glareThreshold {
                glarePixelCount += 1
            }
        }
        
        // If more than 5% of pixels are very bright, consider it glare
        let glareRatio = Double(glarePixelCount) / Double(totalPixels)
        return glareRatio > 0.05
    }
    
    /// Check if document is properly centered in frame
    /// - Parameters:
    ///   - boundaries: The detected document boundaries
    ///   - imageSize: The size of the image
    /// - Returns: True if document is centered
    public func isDocumentCentered(boundaries: DocumentBoundaries, imageSize: CGSize) -> Bool {
        let imageCenter = DocumentPoint(x: Double(imageSize.width) / 2, y: Double(imageSize.height) / 2)
        let docCenter = boundaries.center
        
        // Calculate distance from center
        let dx = abs(docCenter.x - imageCenter.x) / Double(imageSize.width)
        let dy = abs(docCenter.y - imageCenter.y) / Double(imageSize.height)
        
        // Document is centered if within 20% of center
        return dx < 0.2 && dy < 0.2
    }
    
    /// Check if document occupies sufficient area of frame
    /// - Parameters:
    ///   - boundaries: The detected document boundaries
    ///   - imageSize: The size of the image
    /// - Returns: True if document has good size
    public func hasGoodSize(boundaries: DocumentBoundaries, imageSize: CGSize) -> Bool {
        let imageArea = Double(imageSize.width * imageSize.height)
        let docArea = boundaries.area
        let areaRatio = docArea / imageArea
        
        return areaRatio >= minAreaRatio && areaRatio <= maxAreaRatio
    }
    
    /// Cleanup resources
    public func dispose() {
        isInitialized = false
    }
}

// MARK: - Document Processor Error

public enum DocumentProcessorError: Error, LocalizedError {
    case invalidImage
    case detectionFailed
    case processingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for processing"
        case .detectionFailed:
            return "Failed to detect document"
        case .processingFailed:
            return "Document processing failed"
        }
    }
}

// MARK: - ML Model Integration Guide

/*
 To use a custom ML model for document detection:
 
 1. Train or convert a YOLO/SSD model to CoreML
 2. Add the model to your Xcode project
 3. Use it with Vision framework:
 
 ```swift
 let configuration = MLModelConfiguration()
 let mlModel = try await DocumentDetector.load(configuration: configuration)
 let visionModel = try VNCoreMLModel(for: mlModel.model)
 
 let request = VNCoreMLRequest(model: visionModel) { request, error in
     guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
     // Process bounding boxes
 }
 
 let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
 try handler.perform([request])
 ```
 
 Popular models you can use:
 - YOLO for document detection
 - Custom trained models on document datasets
 - Pre-trained models from ML marketplaces
 
 For glare detection, you can train a classification model:
 - Label images as "glare" vs "no glare"
 - Use CreateML or custom training
 - Convert to CoreML
 */

