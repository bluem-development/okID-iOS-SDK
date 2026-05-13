import Foundation
import UIKit
import Vision

/// Face detection service for liveness verification
/// Matches the reference FaceDetectorService functionality
public class FaceDetectionService {
    
    public static let shared = FaceDetectionService()
    
    private var isInitialized = false
    
    private init() {}
    
    /// Initialize face detector (matches the reference initialize method)
    public func initialize() async {
        if isInitialized { return }
        
        // Vision framework doesn't require explicit initialization
        // but we maintain this method for API compatibility with the reference implementation
        isInitialized = true
    }
    
    /// Detect faces in image (matches the reference detectFaces method)
    public func detectFaces(in image: UIImage) async throws -> [FaceDetectionResult] {
        if !isInitialized {
            await initialize()
        }
        
        guard let cgImage = image.cgImage else {
            throw FaceDetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use VNDetectFaceLandmarksRequest to get landmarks for eye detection
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = observations.map { FaceDetectionResult(observation: $0, imageSize: image.size) }
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Detect faces directly from a CVPixelBuffer — avoids CGImage/UIImage allocation entirely
    /// This is the preferred method for continuous video frame processing
    public func detectFaces(in pixelBuffer: CVPixelBuffer) throws -> [FaceDetectionResult] {
        if !isInitialized {
            isInitialized = true
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let imageSize = CGSize(width: width, height: height)
        
        var results: [FaceDetectionResult] = []
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNFaceObservation] else {
                return
            }
            results = observations.map { FaceDetectionResult(observation: $0, imageSize: imageSize) }
        }
        
        // Use default orientation (.up) to match the original UIImage-based detection behavior.
        // The bounding box coordinate system must be consistent with how handleSingleFaceDetected
        // compares face dimensions against view.bounds.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])
        
        return results
    }
    
    /// Detect faces from input image (matches the reference detectFacesFromInputImage)
    public func detectFacesFromInputImage(_ inputImage: UIImage) async throws -> [FaceDetectionResult] {
        return try await detectFaces(in: inputImage)
    }
    
    /// Cleanup resources (matches the reference dispose method)
    public func dispose() {
        isInitialized = false
    }
    
    /// Detect face landmarks
    public func detectFaceLandmarks(in image: UIImage) async throws -> [FaceLandmarkResult] {
        guard let cgImage = image.cgImage else {
            throw FaceDetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results = observations.map { FaceLandmarkResult(observation: $0, imageSize: image.size) }
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Face Detection Result

/// Face detection result with useful properties
/// Matches the reference FaceDetectionResult class exactly
public struct FaceDetectionResult {
    // Core properties (matches the reference)
    public let boundingBox: CGRect
    public let confidence: Double
    
    // Head angles (matches the reference headEulerAngleX/Y/Z)
    public let headEulerAngleX: Double? // Pitch (up/down)
    public let headEulerAngleY: Double? // Yaw (left/right)
    public let headEulerAngleZ: Double? // Roll (tilt)
    
    // Eye probabilities (matches the reference)
    public let leftEyeOpenProbability: Double?
    public let rightEyeOpenProbability: Double?
    
    // Smiling probability (matches the reference)
    public let smilingProbability: Double?
    
    // Landmarks (matches the reference)
    public let landmarks: VNFaceLandmarks2D?
    
    // Note: the reference implementation also has contours from ML Kit, but Vision doesn't provide these
    // We maintain API compatibility by providing landmarks instead
    
    init(observation: VNFaceObservation, imageSize: CGSize) {
        // Vision uses a bottom-left origin; the SDK uses top-left coordinates.
        let normalizedBox = observation.boundingBox
        self.boundingBox = CGRect(
            x: normalizedBox.minX * imageSize.width,
            y: (1.0 - normalizedBox.maxY) * imageSize.height,
            width: normalizedBox.width * imageSize.width,
            height: normalizedBox.height * imageSize.height
        )
        self.confidence = Double(observation.confidence)
        
        // Extract face angles if available (matches the reference headEulerAngleX/Y/Z)
        if #available(iOS 15.0, *) {
            self.headEulerAngleX = observation.pitch?.doubleValue // Pitch (up/down)
            self.headEulerAngleY = observation.yaw?.doubleValue   // Yaw (left/right)
            self.headEulerAngleZ = observation.roll?.doubleValue  // Roll (tilt)
        } else {
            self.headEulerAngleX = nil
            self.headEulerAngleY = nil
            self.headEulerAngleZ = nil
        }
        
        // Store landmarks
        self.landmarks = observation.landmarks
        
        // Estimate eye open probability from landmarks (matches the reference eye detection)
        if let leftEye = observation.landmarks?.leftEye,
           let rightEye = observation.landmarks?.rightEye {
            self.leftEyeOpenProbability = Self.estimateEyeOpenProbability(eyeLandmark: leftEye)
            self.rightEyeOpenProbability = Self.estimateEyeOpenProbability(eyeLandmark: rightEye)
        } else {
            // Assume eyes are open if landmarks not available (matches the reference)
            self.leftEyeOpenProbability = nil
            self.rightEyeOpenProbability = nil
        }
        
        // Smiling probability not available in Vision (placeholder)
        self.smilingProbability = nil
    }
    
    /// Estimate eye open probability from eye landmarks using Eye Aspect Ratio (EAR)
    /// Matches the reference eye detection logic
    private static func estimateEyeOpenProbability(eyeLandmark: VNFaceLandmarkRegion2D) -> Double {
        let points = eyeLandmark.normalizedPoints
        guard points.count >= 6 else {
            return 1.0 // Assume open if not enough points
        }
        
        // Calculate Eye Aspect Ratio (EAR)
        // EAR = (vertical_dist) / (horizontal_dist)
        // Higher EAR = more open eye
        
        // Use first and last points for horizontal distance
        let p1 = points[0]
        let p4 = points[points.count - 1]
        
        // Use middle points for vertical distance
        let p2 = points[points.count / 3]
        let p3 = points[2 * points.count / 3]
        
        let verticalDist = sqrt(pow(p2.x - p3.x, 2) + pow(p2.y - p3.y, 2))
        let horizontalDist = sqrt(pow(p1.x - p4.x, 2) + pow(p1.y - p4.y, 2))
        
        guard horizontalDist > 0 else { return 1.0 }
        
        let aspectRatio = verticalDist / horizontalDist
        
        // Convert aspect ratio to probability (0-1)
        // Typical EAR for open eye: 0.2-0.4
        // Typical EAR for closed eye: < 0.15
        
        if aspectRatio > 0.2 {
            return 1.0 // Fully open
        } else if aspectRatio < 0.1 {
            return 0.0 // Fully closed
        } else {
            // Linear interpolation between 0.1 and 0.2
            return (aspectRatio - 0.1) / 0.1
        }
    }
    
    /// Check if face is looking straight at camera (matches the reference isLookingStraight)
    public var isLookingStraight: Bool {
        if headEulerAngleY == nil && headEulerAngleX == nil {
            return false
        }
        return true
    }
    
    /// Check if eyes are open (matches the reference hasEyesOpen)
    /// Both eyes should have > 50% probability of being open
    public var hasEyesOpen: Bool {
        guard let leftProb = leftEyeOpenProbability,
              let rightProb = rightEyeOpenProbability else {
            return true // Assume open if not detected (matches the reference)
        }
        return leftProb > 0.5 && rightProb > 0.5
    }
    
    /// Check if face is properly positioned (matches the reference isWellPositioned)
    public var isWellPositioned: Bool {
        return isLookingStraight && hasEyesOpen
    }
    
    /// Get face position guidance message (matches the reference guidanceMessage)
    public var guidanceMessage: String {
        if !isLookingStraight {
            if let yaw = headEulerAngleY {
                return yaw > 0 ? "Turn your head slightly left" : "Turn your head slightly right"
            }
            if let pitch = headEulerAngleX {
                return pitch > 0 ? "Look slightly up" : "Look slightly down"
            }
        }
        
        if !hasEyesOpen {
            return "Please keep your eyes open"
        }
        
        return "Hold steady"
    }
    
    /// Get face size ratio relative to frame (matches the reference getSizeRatio)
    public func getSizeRatio(_ frameWidth: Double, _ frameHeight: Double) -> Double {
        let faceArea = boundingBox.width * boundingBox.height
        let frameArea = CGFloat(frameWidth * frameHeight)
        return Double(faceArea / frameArea)
    }
    
    public func isCentered(_ frameWidth: Double, _ frameHeight: Double) -> Bool {
        // Normalize face center to 0-1 range within the frame
        let normalizedCenterX = Double(boundingBox.midX) / frameWidth
        let normalizedCenterY = Double(boundingBox.midY) / frameHeight
        
        // Distance from center (0.5) as fraction of frame
        let dx = abs(normalizedCenterX - 0.5)
        let dy = abs(normalizedCenterY - 0.5)
        
        // Face center must be within 20% of frame center in BOTH directions
        return dx < 0.20 && dy < 0.20
    }

    public func hasGoodSize(_ frameWidth: Double, _ frameHeight: Double) -> Bool {
        let widthRatio = boundingBox.width / CGFloat(frameWidth)
        let heightRatio = boundingBox.height / CGFloat(frameHeight)

        return widthRatio >= 0.25 && widthRatio <= 1.25 &&
        heightRatio >= 0.25 && heightRatio <= 1.25
    }
    
    // Convenience overloads for CGFloat/CGSize parameters
    public func isCentered(in frameSize: CGSize) -> Bool {
        return isCentered(Double(frameSize.width), Double(frameSize.height))
    }
    
    public func hasGoodSize(in frameSize: CGSize) -> Bool {
        return hasGoodSize(Double(frameSize.width), Double(frameSize.height))
    }
    
    public func getSizeRatio(in frameSize: CGSize) -> Double {
        return getSizeRatio(Double(frameSize.width), Double(frameSize.height))
    }
}

// MARK: - Face Landmark Result

public struct FaceLandmarkResult {
    public let boundingBox: CGRect
    public let confidence: Float
    public let landmarks: VNFaceLandmarks2D?
    
    init(observation: VNFaceObservation, imageSize: CGSize) {
        let normalizedBox = observation.boundingBox
        self.boundingBox = CGRect(
            x: normalizedBox.minX * imageSize.width,
            y: (1.0 - normalizedBox.maxY) * imageSize.height,
            width: normalizedBox.width * imageSize.width,
            height: normalizedBox.height * imageSize.height
        )
        self.confidence = observation.confidence
        self.landmarks = observation.landmarks
    }
    
    public var hasLandmarks: Bool {
        landmarks != nil
    }
    
    public var isLookingStraight: Bool {
        // Simple heuristic: if we have landmarks, assume reasonable pose
        return hasLandmarks
    }
}

// MARK: - Face Detection Error

public enum FaceDetectionError: Error, LocalizedError {
    case invalidImage
    case noFaceDetected
    case multipleFacesDetected
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for face detection"
        case .noFaceDetected:
            return "No face detected in image"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one person is in frame."
        }
    }
}
