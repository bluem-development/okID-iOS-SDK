import Foundation
import UIKit
import CoreML
import Vision
import CoreImage

private let logger = Logger.face

/// Result from age/gender estimation
public struct AgeGenderResult {
    public let age: Double
    public let gender: String
    public let genderConfidence: Double
    
    public init(age: Double, gender: String, genderConfidence: Double) {
        self.age = age
        self.gender = gender
        self.genderConfidence = genderConfidence
    }
    
    public var description: String {
        return "AgeGenderResult(age: \(String(format: "%.1f", age)), gender: \(gender), confidence: \(String(format: "%.1f%%", genderConfidence * 100)))"
    }
}

/// Age and Gender estimation service using CoreML model.
/// Converted from face-api.js AgeGenderNet — same architecture as the Flutter TFLite version.
///
/// Model: age_gender_model.mlpackage
/// Outputs: age (Float) and gender probabilities.
/// The bundled ViT model uses female as the positive class.
public class AgeGenderEstimator {
    
    public static let shared = AgeGenderEstimator()
    private static let imageNetMean: (Float, Float, Float) = (0.485, 0.456, 0.406)
    private static let imageNetStd: (Float, Float, Float) = (0.229, 0.224, 0.225)
    
    private var mlModel: MLModel?
    private var vnModel: VNCoreMLModel?
    private var isInitialized = false
    
    /// Default fallback input size used when the model description does not expose dimensions.
    public static let inputSize: Int = 64
    
    public init() {}
    
    // MARK: - Initialization
    
    /// Initialize the CoreML model from the bundled .mlpackage resource.
    /// Never throws — if the model can't be loaded, heuristic fallback is used.
    public func initialize() async {
        guard !isInitialized else { return }
        
        do {
            let configuration = MLModelConfiguration()
            // The quantized age/gender mlprogram has been crashing inside Apple's
            // MPSGraph backend (`MPSGraphExecutable` / `MIL pass manager failed`).
            // Force CPU inference to avoid that runtime abort path.
            configuration.computeUnits = .cpuOnly
            
            if let compiledURL = Bundle.module.url(forResource: "age_gender_model", withExtension: "mlmodelc") {
                logger.info("Found compiled age/gender model at: \(compiledURL.path)")
                mlModel = try MLModel(contentsOf: compiledURL, configuration: configuration)
            } else if let packageURL = Bundle.module.url(forResource: "age_gender_model", withExtension: "mlpackage") {
                logger.info("Found age/gender mlpackage at: \(packageURL.path)")
                let compiledURL = try MLModel.compileModel(at: packageURL)
                mlModel = try MLModel(contentsOf: compiledURL, configuration: configuration)
            } else {
                logger.warning("age_gender_model not found in bundle, using heuristic fallback")
            }
            
            if let model = mlModel {
                if let inputDescription = model.modelDescription.inputDescriptionsByName.values.first,
                   inputDescription.type == .image {
                    vnModel = try VNCoreMLModel(for: model)
                } else {
                    // This model uses a tensor/multi-array input, so Vision wrapping is invalid.
                    vnModel = nil
                }
                logger.info("Age/Gender CoreML model loaded successfully")
            }
        } catch {
            logger.warning("Failed to load Age/Gender CoreML model: \(error). Using heuristic fallback.")
            mlModel = nil
            vnModel = nil
        }
        
        isInitialized = true
    }
    
    // MARK: - Estimation
    
    /// Estimate age and gender from a cropped face image.
    /// The image should be the face region from the camera frame.
    /// Always returns a result — falls back to heuristic if CoreML model is unavailable.
    public func estimate(faceImage: UIImage) async throws -> AgeGenderResult {
        if !isInitialized {
            await initialize()
        }
        
        guard let normalizedImage = faceImage.normalizedUpImage(),
              let cgImage = normalizedImage.cgImage else {
            throw AgeGenderError.preprocessingFailed
        }
        
        // Try CoreML model first; fall back to heuristic if model not available
        if let model = mlModel {
            do {
                return try estimateWithCoreML(cgImage: cgImage, model: model)
            } catch {
                logger.warning("CoreML inference failed: \(error). Using heuristic fallback.")
                return try await estimateWithHeuristic(cgImage: cgImage, imageSize: normalizedImage.size)
            }
        } else {
            return try await estimateWithHeuristic(cgImage: cgImage, imageSize: normalizedImage.size)
        }
    }
    
    // MARK: - CoreML Inference
    
    /// Run inference using the CoreML model directly (no VNCoreMLRequest).
    /// For image inputs the pixel buffer is sized to match the model's MLImageConstraint.
    /// For MLMultiArray inputs the tensor layout is inferred from the model shape.
    private func estimateWithCoreML(cgImage: CGImage, model: MLModel) throws -> AgeGenderResult {
        let inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "input"
        let inputDescription = model.modelDescription.inputDescriptionsByName[inputName]
        
        let prediction: MLFeatureProvider
        
        if inputDescription?.type == .image {
            // Read the size the model actually requires from its MLImageConstraint.
            // Hardcoding 64 here causes "Image size 64×64 not in allowed set" when the
            // compiled model was built with a different input resolution (e.g. 128×128).
            let requiredSize: Int
            if let constraint = inputDescription?.imageConstraint, constraint.pixelsHigh > 0 {
                requiredSize = Int(constraint.pixelsHigh)
            } else {
                requiredSize = AgeGenderEstimator.inputSize
            }
            logger.debug("Model image input requires \(requiredSize)×\(requiredSize) px")
            
            let pixelBuffer = try createPixelBuffer(from: cgImage, size: requiredSize)
            let input = try MLDictionaryFeatureProvider(dictionary: [inputName: pixelBuffer])
            prediction = try model.prediction(from: input)
        } else {
            let inputSpec = resolveTensorInputSpec(from: inputDescription)
            logger.debug("Model tensor input requires \(inputSpec.width)×\(inputSpec.height), channelsFirst=\(inputSpec.channelsFirst)")
            let pixelBuffer = try createPixelBuffer(from: cgImage, width: inputSpec.width, height: inputSpec.height)
            let multiArray = try createMultiArray(from: pixelBuffer, spec: inputSpec)
            let input = try MLDictionaryFeatureProvider(dictionary: [inputName: multiArray])
            prediction = try model.prediction(from: input)
        }
        
        return try parseModelOutputs(prediction: prediction, modelDescription: model.modelDescription)
    }
    
    /// Parse the model's output features into an AgeGenderResult.
    /// Handles different output naming conventions.
    private func parseModelOutputs(prediction: MLFeatureProvider, modelDescription: MLModelDescription) throws -> AgeGenderResult {
        let outputNames = modelDescription.outputDescriptionsByName.keys.sorted()
        
        logger.debug("Model output names: \(outputNames)")
        
        var ageValue: Double?
        var genderProbs: (male: Double, female: Double)?
        
        for name in outputNames {
            guard let feature = prediction.featureValue(for: name) else { continue }
            
            let desc = modelDescription.outputDescriptionsByName[name]
            let shape = (desc?.multiArrayConstraint?.shape as? [Int]) ?? []
            
            if let multiArray = feature.multiArrayValue {
                let count = multiArray.count
                
                if count == 1 {
                    // Single value → age output
                    ageValue = multiArray[0].doubleValue
                    logger.debug("Age output [\(name)]: \(multiArray[0].doubleValue)")
                } else if count == 2 {
                    // The exported ViT model's gender output is ordered [female, male].
                    let val0 = multiArray[0].doubleValue
                    let val1 = multiArray[1].doubleValue
                    
                    // Apply softmax if values aren't already probabilities
                    let (female, male) = softmax2(val0, val1)
                    genderProbs = (male: male, female: female)
                    logger.debug("Gender output [\(name)]: male=\(String(format: "%.3f", male)), female=\(String(format: "%.3f", female))")
                } else {
                    logger.debug("Unknown output [\(name)] with \(count) values, shape: \(shape)")
                }
            } else if feature.type == .double {
                ageValue = feature.doubleValue
            } else if feature.type == .int64 {
                ageValue = Double(feature.int64Value)
            }
        }
        
        guard let age = ageValue else {
            throw AgeGenderError.inferenceFailed
        }
        
        let gender: String
        let confidence: Double
        
        if let probs = genderProbs {
            let isMale = probs.male > probs.female
            gender = isMale ? "male" : "female"
            confidence = isMale ? probs.male : probs.female
        } else {
            // If no gender output found, return neutral
            gender = "male"
            confidence = 0.50
        }
        
        return AgeGenderResult(
            age: min(max(age, 1.0), 100.0),
            gender: gender,
            genderConfidence: confidence
        )
    }
    
    // MARK: - Image Preprocessing
    
    private struct TensorInputSpec {
        let shape: [NSNumber]
        let width: Int
        let height: Int
        let channelsFirst: Bool
    }
    
    private func resolveTensorInputSpec(from inputDescription: MLFeatureDescription?) -> TensorInputSpec {
        if let rawShape = inputDescription?.multiArrayConstraint?.shape as? [NSNumber], rawShape.count == 4 {
            let shape = rawShape.map { $0.intValue }
            if shape[1] == 3 {
                return TensorInputSpec(
                    shape: rawShape,
                    width: max(shape[3], 1),
                    height: max(shape[2], 1),
                    channelsFirst: true
                )
            }
            if shape[3] == 3 {
                return TensorInputSpec(
                    shape: rawShape,
                    width: max(shape[2], 1),
                    height: max(shape[1], 1),
                    channelsFirst: false
                )
            }
        }
        
        return TensorInputSpec(
            shape: [1, NSNumber(value: AgeGenderEstimator.inputSize), NSNumber(value: AgeGenderEstimator.inputSize), 3],
            width: AgeGenderEstimator.inputSize,
            height: AgeGenderEstimator.inputSize,
            channelsFirst: false
        )
    }
    
    /// Create a BGRA CVPixelBuffer from a CGImage, resized for the Core ML model.
    private func createPixelBuffer(from cgImage: CGImage, size: Int) throws -> CVPixelBuffer {
        try createPixelBuffer(from: cgImage, width: size, height: size)
    }
    
    /// Create a BGRA CVPixelBuffer from a CGImage using explicit width/height.
    private func createPixelBuffer(from cgImage: CGImage, width: Int, height: Int) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw AgeGenderError.preprocessingFailed
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            throw AgeGenderError.preprocessingFailed
        }
        
        // Match ViT preprocessing more closely: preserve aspect ratio and center-crop
        // instead of stretching the face into a square.
        let sourceWidth = CGFloat(cgImage.width)
        let sourceHeight = CGFloat(cgImage.height)
        let targetWidth = CGFloat(width)
        let targetHeight = CGFloat(height)
        let scale = max(targetWidth / sourceWidth, targetHeight / sourceHeight)
        let drawWidth = sourceWidth * scale
        let drawHeight = sourceHeight * scale
        let drawRect = CGRect(
            x: (targetWidth - drawWidth) / 2.0,
            y: (targetHeight - drawHeight) / 2.0,
            width: drawWidth,
            height: drawHeight
        )
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: drawRect)
        
        return buffer
    }
    
    /// Create an MLMultiArray from a CVPixelBuffer using the ViT ImageProcessor normalization.
    private func createMultiArray(from pixelBuffer: CVPixelBuffer, spec: TensorInputSpec) throws -> MLMultiArray {
        let width = spec.width
        let height = spec.height
        let multiArray = try MLMultiArray(shape: spec.shape, dataType: .float32)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw AgeGenderError.preprocessingFailed
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                // BGRA format -> RGB, then apply the Hugging Face ViT normalization:
                // rescale to [0,1], subtract mean, divide by std.
                let b = ((Float(ptr[offset + 0]) / 255.0) - Self.imageNetMean.2) / Self.imageNetStd.2
                let g = ((Float(ptr[offset + 1]) / 255.0) - Self.imageNetMean.1) / Self.imageNetStd.1
                let r = ((Float(ptr[offset + 2]) / 255.0) - Self.imageNetMean.0) / Self.imageNetStd.0
                
                if spec.channelsFirst {
                    let planeSize = height * width
                    multiArray[y * width + x] = NSNumber(value: r)
                    multiArray[planeSize + y * width + x] = NSNumber(value: g)
                    multiArray[planeSize * 2 + y * width + x] = NSNumber(value: b)
                } else {
                    let baseIdx = y * width * 3 + x * 3
                    multiArray[baseIdx + 0] = NSNumber(value: r)
                    multiArray[baseIdx + 1] = NSNumber(value: g)
                    multiArray[baseIdx + 2] = NSNumber(value: b)
                }
            }
        }
        
        return multiArray
    }
    
    // MARK: - Heuristic Fallback
    
    /// Fallback estimation using Vision landmarks when CoreML model isn't available.
    private func estimateWithHeuristic(cgImage: CGImage, imageSize: CGSize) async throws -> AgeGenderResult {
        let observations = try await detectFaceLandmarks(cgImage: cgImage)
        
        guard let face = observations.first else {
            return AgeGenderResult(age: 30.0, gender: "male", genderConfidence: 0.50)
        }
        
        let (gender, genderConf) = analyzeGenderHeuristic(observation: face)
        let age = analyzeAgeHeuristic(observation: face, cgImage: cgImage)
        
        return AgeGenderResult(age: age, gender: gender, genderConfidence: genderConf)
    }
    
    /// Run Vision face landmark detection
    private func detectFaceLandmarks(cgImage: CGImage) async throws -> [VNFaceObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNFaceObservation]) ?? []
                continuation.resume(returning: observations)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Heuristic gender estimation from facial geometry
    private func analyzeGenderHeuristic(observation: VNFaceObservation) -> (String, Double) {
        let bbox = observation.boundingBox
        let landmarks = observation.landmarks
        
        var maleScore: Double = 0.0
        var featureCount: Double = 0.0
        
        // Face aspect ratio
        let faceAspect = bbox.width / max(bbox.height, 0.001)
        let normalizedAspect = (Double(faceAspect) - 0.70) / 0.15
        maleScore += max(0, min(1, normalizedAspect))
        featureCount += 1
        
        // Jawline angularity
        if let faceContour = landmarks?.faceContour {
            let jawPoints = faceContour.normalizedPoints
            if jawPoints.count >= 6 {
                let jawWidth = abs(jawPoints.first!.x - jawPoints.last!.x)
                let midIdx = jawPoints.count / 3
                let endIdx = jawPoints.count - midIdx - 1
                let cheekWidth = abs(jawPoints[midIdx].x - jawPoints[endIdx].x)
                let jawRatio = Double(jawWidth / max(cheekWidth, 0.001))
                let normalizedJaw = (jawRatio - 0.55) / 0.35
                maleScore += max(0, min(1, normalizedJaw))
                featureCount += 1
            }
        }
        
        // Nose width relative to inter-eye distance
        if let nose = landmarks?.nose,
           let leftEye = landmarks?.leftEye,
           let rightEye = landmarks?.rightEye {
            let leftCenter = leftEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let rightCenter = rightEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let lc = CGFloat(max(leftEye.normalizedPoints.count, 1))
            let rc = CGFloat(max(rightEye.normalizedPoints.count, 1))
            let interEyeDist = abs(rightCenter.x / rc - leftCenter.x / lc)
            
            let nosePoints = nose.normalizedPoints
            if nosePoints.count >= 4 && interEyeDist > 0.01 {
                let noseXs = nosePoints.map { $0.x }
                let noseWidth = (noseXs.max() ?? 0) - (noseXs.min() ?? 0)
                let noseRatio = Double(noseWidth / interEyeDist)
                let normalizedNose = (noseRatio - 0.35) / 0.30
                maleScore += max(0, min(1, normalizedNose))
                featureCount += 1
            }
        }
        
        guard featureCount > 0 else {
            return ("male", 0.50)
        }
        
        let avgMaleScore = maleScore / featureCount
        let isMale = avgMaleScore > 0.50
        let confidence = 0.50 + abs(avgMaleScore - 0.50) * 0.98
        
        return (isMale ? "male" : "female", min(confidence, 0.99))
    }
    
    /// Heuristic age estimation from skin texture + facial proportions
    private func analyzeAgeHeuristic(observation: VNFaceObservation, cgImage: CGImage) -> Double {
        let bbox = observation.boundingBox
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)
        
        // Skin texture analysis
        let faceX = bbox.origin.x * imgWidth
        let faceY = (1.0 - bbox.origin.y - bbox.height) * imgHeight
        let faceW = bbox.width * imgWidth
        let faceH = bbox.height * imgHeight
        
        let regions: [CGRect] = [
            CGRect(x: faceX + faceW * 0.30, y: faceY + faceH * 0.02, width: faceW * 0.40, height: faceH * 0.15),
            CGRect(x: faceX + faceW * 0.08, y: faceY + faceH * 0.45, width: faceW * 0.25, height: faceH * 0.20),
            CGRect(x: faceX + faceW * 0.67, y: faceY + faceH * 0.45, width: faceW * 0.25, height: faceH * 0.20),
        ]
        
        var totalVariance: Double = 0.0
        var validRegions = 0
        
        for region in regions {
            let clampedRect = CGRect(
                x: max(0, min(region.origin.x, imgWidth - 2)),
                y: max(0, min(region.origin.y, imgHeight - 2)),
                width: min(region.width, imgWidth - region.origin.x),
                height: min(region.height, imgHeight - region.origin.y)
            )
            
            guard clampedRect.width > 4 && clampedRect.height > 4,
                  let cropped = cgImage.cropping(to: clampedRect) else { continue }
            
            if let variance = computeVariance(cgImage: cropped) {
                totalVariance += variance
                validRegions += 1
            }
        }
        
        if validRegions > 0 {
            let avgVariance = totalVariance / Double(validRegions)
            let normalizedVariance = min(max((avgVariance - 200.0) / 1800.0, 0.0), 1.0)
            return min(max(18.0 + normalizedVariance * 52.0, 16.0), 75.0)
        }
        
        return 30.0
    }
    
    /// Compute grayscale variance for a skin region
    private func computeVariance(cgImage: CGImage) -> Double? {
        let width = cgImage.width
        let height = cgImage.height
        guard width >= 4 && height >= 4 else { return nil }
        
        var grayPixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &grayPixels,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalLocalVariance: Double = 0.0
        var count: Int = 0
        let step = max(1, min(width, height) / 50)
        
        for y in stride(from: 1, to: height - 1, by: step) {
            for x in stride(from: 1, to: width - 1, by: step) {
                var sum: Double = 0
                var sumSq: Double = 0
                for dy in -1...1 {
                    for dx in -1...1 {
                        let val = Double(grayPixels[(y + dy) * width + (x + dx)])
                        sum += val
                        sumSq += val * val
                    }
                }
                let mean = sum / 9.0
                totalLocalVariance += max(0, (sumSq / 9.0) - (mean * mean))
                count += 1
            }
        }
        
        return count > 0 ? totalLocalVariance / Double(count) : nil
    }
    
    // MARK: - Utilities
    
    /// Two-element softmax
    private func softmax2(_ a: Double, _ b: Double) -> (Double, Double) {
        // If values already look like probabilities (both in [0,1] and sum ≈ 1)
        if a >= 0 && b >= 0 && abs(a + b - 1.0) < 0.1 {
            return (a, b)
        }
        let maxVal = max(a, b)
        let expA = exp(a - maxVal)
        let expB = exp(b - maxVal)
        let sumExp = expA + expB
        return (expA / sumExp, expB / sumExp)
    }
    
    /// Cleanup resources
    public func dispose() {
        mlModel = nil
        vnModel = nil
        isInitialized = false
    }
}

// MARK: - Age/Gender Error

public enum AgeGenderError: Error, LocalizedError {
    case modelNotInitialized
    case preprocessingFailed
    case inferenceFailed
    
    public var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "Age/Gender model is not initialized"
        case .preprocessingFailed:
            return "Failed to preprocess image"
        case .inferenceFailed:
            return "Model inference failed"
        }
    }
}
