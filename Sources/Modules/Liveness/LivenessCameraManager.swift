import Foundation
import UIKit
import CoreImage

private let logger = Logger.liveness

// MARK: - Liveness Camera Manager

/// Manages business logic for the liveness camera capture screen
/// Handles: face detection evaluation, state machine transitions,
/// countdown/delay timers, biometric data collection & aggregation
class LivenessCameraManager {
    
    // MARK: - Properties
    
    private let faceDetector = FaceDetectionService.shared
    private let ageGenderEstimator = AgeGenderEstimator.shared
    private let state: LivenessCameraState
    private let ciContext = CIContext()
    
    // Timers (owned by manager, not controller)
    private var faceCheckTimer: Timer?
    private var countdownTimer: Timer?
    private var delayTimer: Timer?
    private var biometricCollectionTimer: Timer?
    private var lastBiometricCollectionTime: CFTimeInterval = 0
    
    // MARK: - Initialization
    
    init(state: LivenessCameraState) {
        self.state = state
    }
    
    // MARK: - Setup
    
    /// Initialize face detector model
    func initializeFaceDetector() async {
        await faceDetector.initialize()
        await ageGenderEstimator.initialize()
    }
    
    /// Start periodic timers for face detection and biometric collection
    func startTimers() {
        // Face detection timer (every 300ms) - actual detection happens in video delegate
        faceCheckTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: true
        ) { _ in
            // Face detection happens in video delegate
        }
        
        // Live biometric collection now happens from fresh camera frames during
        // hold-steady/countdown. A timer would reuse stale face geometry.
    }
    
    // MARK: - Cleanup
    
    /// Invalidate all timers (for prepareForRemoval)
    func invalidateTimers() {
        faceCheckTimer?.invalidate()
        faceCheckTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        biometricCollectionTimer?.invalidate()
        biometricCollectionTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
    }
    
    /// Full cleanup
    func dispose() {
        invalidateTimers()
        state.biometricReadings.removeAll()
        state.currentBiometricDisplay = nil
    }
    
    // MARK: - Face Detection Handling
    
    /// Detect faces in image using the face detection service
    func detectFaces(in image: UIImage) async throws -> [FaceDetectionResult] {
        return try await faceDetector.detectFaces(in: image)
    }
    
    /// Detect faces directly from pixel buffer — zero UIImage allocation
    func detectFaces(in pixelBuffer: CVPixelBuffer) throws -> [FaceDetectionResult] {
        return try faceDetector.detectFaces(in: pixelBuffer)
    }
    
    /// Handle when no face is detected
    func handleNoFaceDetected() {
        cancelCountdown()
        state.lastDetectedFace = nil
        
        if state.captureState != .detectingFace {
            state.captureState = .detectingFace
            state.statusMessage = "Position your face in the oval"
            state.onUIUpdateNeeded?()
        }
    }
    
    /// Handle multiple faces detected
    func handleMultipleFaces() {
        cancelCountdown()
        state.lastDetectedFace = nil
        
        state.captureState = .detectingFace
        state.statusMessage = "Multiple faces detected. Please have only one person in frame."
        state.onUIUpdateNeeded?()
    }
    
    /// Handle single face detected — evaluate quality and advance state machine.
    /// `pixelBufferSize` must be the CVPixelBuffer dimensions (same coordinate space as face.boundingBox).
    func handleSingleFaceDetected(_ face: FaceDetectionResult, pixelBuffer: CVPixelBuffer, pixelBufferSize: CGSize) {
        state.lastDetectedFace = face
        
        // Use pixel buffer dimensions — the bounding box is in this coordinate space.
        // No swapping needed: both are already in the same reference frame.
        let frameWidth = pixelBufferSize.width
        let frameHeight = pixelBufferSize.height
        
        // Check face quality
        let isLookingStraight = face.isLookingStraight
        let hasEyesOpen = face.hasEyesOpen
        let hasGoodSize = face.hasGoodSize(Double(frameWidth), Double(frameHeight))
        let isCentered = face.isCentered(Double(frameWidth), Double(frameHeight))
        
        // Debug logging
        let faceWidthRatio = (face.boundingBox.width / frameWidth * 100)
        let faceHeightRatio = (face.boundingBox.height / frameHeight * 100)
        logger.debug("Face - Straight: \(isLookingStraight), Eyes: \(hasEyesOpen), Size: \(hasGoodSize) (W:\(String(format: "%.1f", faceWidthRatio))%, H:\(String(format: "%.1f", faceHeightRatio))%, need 20-80%), Centered: \(isCentered)")
        
        // If delay or countdown is active, let it complete
        if state.captureState == .delayBeforeCountdown || state.captureState == .countdown {
            collectLiveBiometricIfNeeded(face: face, pixelBuffer: pixelBuffer)
            logger.debug("Delay/countdown in progress - allowing to complete")
            return
        }
        
        // PRIORITY 1: Check face size
        if !hasGoodSize {
            state.captureState = .faceFound
            let widthRatio = face.boundingBox.width / frameWidth
            if widthRatio < 0.25 {
                state.statusMessage = "Move closer to the camera"
            } else {
                state.statusMessage = "Move back from the camera"
            }
            state.onUIUpdateNeeded?()
        }
        // PRIORITY 2: Check face centering
        else if !isCentered {
            state.captureState = .faceFound
            
            // Normalize both face center and frame center to 0-1 range
            // so direction is always correct regardless of resolution
            let normalizedFaceCenterX = face.boundingBox.midX / frameWidth
            let normalizedFaceCenterY = face.boundingBox.midY / frameHeight
            
            let dx = normalizedFaceCenterX - 0.5  // positive = face is to the right
            let dy = normalizedFaceCenterY - 0.5  // positive = face is below center
            
            var message = "Move your face "
            if abs(dy) > abs(dx) {
                message += dy > 0 ? "down" : "up"
            } else {
                message += dx > 0 ? "right" : "left"
            }
            
            state.statusMessage = message
            state.onUIUpdateNeeded?()
        }
        // PRIORITY 3: Check head angle
        else if !isLookingStraight {
            state.captureState = .faceFound
            state.statusMessage = face.guidanceMessage
            state.onUIUpdateNeeded?()
        }
        // PRIORITY 4: Check eyes open
        else if !hasEyesOpen {
            state.captureState = .faceFound
            state.statusMessage = "Please keep your eyes open"
            state.onUIUpdateNeeded?()
        }
        // ALL CHECKS PASSED: Face is perfect!
        else {
            if state.captureState != .delayBeforeCountdown {
                logger.debug("Face properly positioned - starting 3-second delay...")
                startDelayBeforeCountdown()
            }
        }
    }
    
    // MARK: - Countdown Logic
    
    /// Start 3-second delay before countdown
    private func startDelayBeforeCountdown() {
        cancelCountdown()
        
        state.captureState = .delayBeforeCountdown
        state.delayRemaining = 3
        state.statusMessage = "Perfect! Hold steady"
        state.onUIUpdateNeeded?()
        
        delayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.state.delayRemaining -= 1
            
            if self.state.delayRemaining <= 0 {
                timer.invalidate()
                self.startCountdown()
            }
        }
    }
    
    /// Start visible countdown
    private func startCountdown() {
        state.captureState = .countdown
        state.countdownRemaining = 3
        state.statusMessage = "Hold steady"
        state.onUIUpdateNeeded?()
        state.onStartCountdownDisplay?()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.state.countdownRemaining -= 1
            
            if self.state.countdownRemaining <= 0 {
                timer.invalidate()
                self.onCountdownComplete()
            }
            // countdownRemaining didSet triggers onCountdownChanged for UI update
        }
    }
    
    /// Cancel countdown and delay timers
    func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        state.onCountdownVisibilityChanged?(false)
    }
    
    /// Countdown complete — trigger capture
    private func onCountdownComplete() {
        state.captureState = .capturing
        state.statusMessage = "Capturing..."
        state.onUIUpdateNeeded?()
        state.onCaptureTriggered?()
    }
    
    // MARK: - Biometric Data Collection
    
    private func collectLiveBiometricIfNeeded(face: FaceDetectionResult, pixelBuffer: CVPixelBuffer) {
        guard !state.isProcessingBiometric, !state.isCameraCapturing else { return }
        
        let now = CACurrentMediaTime()
        guard now - lastBiometricCollectionTime >= 0.5 else { return }
        lastBiometricCollectionTime = now
        state.isProcessingBiometric = true
        
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.state.isProcessingBiometric = false }
            
            do {
                guard let faceImage = try self.cropFaceImage(from: pixelBuffer, face: face) else { return }
                let result = try await self.ageGenderEstimator.estimate(faceImage: faceImage)
                await self.pushBiometricReading(
                    AgeGenderReading(
                        age: result.age,
                        gender: result.gender,
                        confidence: result.genderConfidence,
                        timestamp: Date()
                    )
                )
            } catch {
                logger.warning("Live age/gender estimation failed: \(error)")
            }
        }
    }
    
    @MainActor
    private func pushBiometricReading(_ reading: AgeGenderReading) {
        state.biometricReadings.append(reading)
        
        let readingsToDisplay = state.biometricReadings.suffix(20)
        let avgAge = readingsToDisplay.map { $0.age }.reduce(0, +) / Double(readingsToDisplay.count)
        let genderCounts = Dictionary(grouping: readingsToDisplay, by: { $0.gender })
        let mostCommonGender = genderCounts.max(by: { $0.value.count < $1.value.count })?.key ?? "unknown"
        let avgConfidence = readingsToDisplay.map { $0.confidence }.reduce(0, +) / Double(readingsToDisplay.count)
        
        state.currentBiometricDisplay = AgeGenderReading(
            age: avgAge,
            gender: mostCommonGender,
            confidence: avgConfidence,
            timestamp: Date()
        )
    }
    
    private func cropFaceImage(from pixelBuffer: CVPixelBuffer, face: FaceDetectionResult) throws -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent.integral
        
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else {
            return nil
        }
        
        let paddingX = face.boundingBox.width * 0.20
        let paddingY = face.boundingBox.height * 0.28
        let x = max(0, face.boundingBox.minX - paddingX)
        let y = max(0, face.boundingBox.minY - paddingY)
        let width = min(extent.width - x, face.boundingBox.width + paddingX * 2)
        let height = min(extent.height - y, face.boundingBox.height + paddingY * 2)
        
        let cropRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        ).integral
        
        guard cropRect.width > 8,
              cropRect.height > 8,
              let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cropped)
    }
    
    // MARK: - Face Geometry Analysis
    
    /// Estimate gender from facial landmark geometry.
    /// Uses multiple facial structure ratios that differ statistically between male and female faces:
    /// - Jawline width relative to face height (males tend to have wider, more angular jaws)
    /// - Eyebrow-to-eye distance (males tend to have lower, thicker brow ridges)
    /// - Face width-to-height ratio (males tend to have wider faces)
    /// - Nose width relative to face width (males tend to have wider noses)
    /// Note: This is a heuristic based on population averages, not a trained ML model.
    private func estimateGenderFromLandmarks(_ face: FaceDetectionResult) -> (String, Double) {
        guard let landmarks = face.landmarks else {
            // Without landmarks, use bounding box aspect ratio as a rough fallback
            let aspectRatio = face.boundingBox.width / max(face.boundingBox.height, 1)
            let isMale = aspectRatio > 0.78
            return (isMale ? "male" : "female", 0.55)
        }
        
        var maleScore: Double = 0.0
        var featureCount: Double = 0.0
        
        // 1. Face aspect ratio (width/height) — males tend wider (~0.80), females narrower (~0.74)
        let faceAspect = face.boundingBox.width / max(face.boundingBox.height, 1)
        if faceAspect > 0 {
            // Higher ratio → more male
            let normalizedAspect = (Double(faceAspect) - 0.70) / 0.15  // 0.70-0.85 range → 0-1
            maleScore += max(0, min(1, normalizedAspect))
            featureCount += 1
        }
        
        // 2. Jawline spread — males have wider, more angular jawlines
        if let faceContour = landmarks.faceContour {
            let jawPoints = faceContour.normalizedPoints
            if jawPoints.count >= 6 {
                // Width at jaw (first and last points) vs width at cheekbone level (1/3 points)
                let jawWidth = abs(jawPoints.first!.x - jawPoints.last!.x)
                let midIdx = jawPoints.count / 3
                let endIdx = jawPoints.count - midIdx - 1
                let cheekWidth = abs(jawPoints[midIdx].x - jawPoints[endIdx].x)
                
                // Males: jaw is closer to cheek width (angular). Females: jaw much narrower (tapered)
                let jawRatio = Double(jawWidth / max(cheekWidth, 0.001))
                // Higher ratio → more angular → more male
                let normalizedJaw = (jawRatio - 0.55) / 0.35  // 0.55-0.90 range → 0-1
                maleScore += max(0, min(1, normalizedJaw))
                featureCount += 1
            }
        }
        
        // 3. Nose width relative to inter-eye distance — males tend to have wider noses
        if let nose = landmarks.nose,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            let nosePoints = nose.normalizedPoints
            let leftEyeCenter = leftEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let rightEyeCenter = rightEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            
            let leftCount = CGFloat(max(leftEye.normalizedPoints.count, 1))
            let rightCount = CGFloat(max(rightEye.normalizedPoints.count, 1))
            
            let interEyeDist = abs(rightEyeCenter.x / rightCount - leftEyeCenter.x / leftCount)
            
            if nosePoints.count >= 4 && interEyeDist > 0.01 {
                // Nose width from leftmost to rightmost nose point
                let noseXs = nosePoints.map { $0.x }
                let noseWidth = (noseXs.max() ?? 0) - (noseXs.min() ?? 0)
                let noseRatio = Double(noseWidth / interEyeDist)
                // Males: higher nose-to-eye ratio
                let normalizedNose = (noseRatio - 0.35) / 0.30  // 0.35-0.65 range → 0-1
                maleScore += max(0, min(1, normalizedNose))
                featureCount += 1
            }
        }
        
        // 4. Eyebrow thickness/position — males tend to have lower, thicker brows
        if let leftBrow = landmarks.leftEyebrow,
           let leftEye = landmarks.leftEye {
            let browPoints = leftBrow.normalizedPoints
            let eyePoints = leftEye.normalizedPoints
            
            if !browPoints.isEmpty && !eyePoints.isEmpty {
                let browAvgY = browPoints.map { $0.y }.reduce(0, +) / CGFloat(browPoints.count)
                let eyeAvgY = eyePoints.map { $0.y }.reduce(0, +) / CGFloat(eyePoints.count)
                let browEyeDist = Double(abs(browAvgY - eyeAvgY))
                
                // Males: smaller brow-eye distance (brow sits lower/closer to eye)
                let normalizedBrow = 1.0 - ((browEyeDist - 0.02) / 0.08)  // 0.02-0.10 range inverted
                maleScore += max(0, min(1, normalizedBrow))
                featureCount += 1
            }
        }
        
        guard featureCount > 0 else {
            return ("male", 0.50)
        }
        
        let avgMaleScore = maleScore / featureCount
        let isMale = avgMaleScore > 0.50
        // Confidence: how far from the 0.5 decision boundary
        let confidence = 0.50 + abs(avgMaleScore - 0.50) * 0.98
        
        return (isMale ? "male" : "female", min(confidence, 0.99))
    }
    
    /// Estimate age from facial landmark geometry using multiple facial proportion
    /// features that genuinely correlate with age.
    /// Note: This is a heuristic (no ML model). In the final AgeGenderEstimator,
    /// skin texture analysis from actual pixels is also used for higher accuracy.
    private func estimateAgeFromLandmarks(_ face: FaceDetectionResult) -> Double {
        guard let landmarks = face.landmarks else {
            return 30.0
        }
        
        var weightedSum: Double = 0.0
        var totalWeight: Double = 0.0
        
        // 1. Eye openness: younger people have wider-open eyes (higher aspect ratio)
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftPts = leftEye.normalizedPoints
            let rightPts = rightEye.normalizedPoints
            
            if leftPts.count >= 6 && rightPts.count >= 6 {
                let leftH = (leftPts.map { $0.y }.max() ?? 0) - (leftPts.map { $0.y }.min() ?? 0)
                let leftW = (leftPts.map { $0.x }.max() ?? 0) - (leftPts.map { $0.x }.min() ?? 0)
                let rightH = (rightPts.map { $0.y }.max() ?? 0) - (rightPts.map { $0.y }.min() ?? 0)
                let rightW = (rightPts.map { $0.x }.max() ?? 0) - (rightPts.map { $0.x }.min() ?? 0)
                
                let leftAspect = leftW > 0.01 ? Double(leftH / leftW) : 0.35
                let rightAspect = rightW > 0.01 ? Double(rightH / rightW) : 0.35
                let avgEyeAspect = (leftAspect + rightAspect) / 2.0
                
                // Higher aspect → younger. Typical range: 0.20 (elderly) to 0.50 (young)
                let eyeAge = 18.0 + (1.0 - min(max((avgEyeAspect - 0.20) / 0.30, 0.0), 1.0)) * 52.0
                weightedSum += eyeAge * 1.5
                totalWeight += 1.5
            }
        }
        
        // 2. Lip fullness: thinner lips correlate with older age
        if let outerLips = landmarks.outerLips, let innerLips = landmarks.innerLips {
            let outerPts = outerLips.normalizedPoints
            let innerPts = innerLips.normalizedPoints
            
            if outerPts.count >= 6 && innerPts.count >= 4 {
                let outerHeight = (outerPts.map { $0.y }.max() ?? 0) - (outerPts.map { $0.y }.min() ?? 0)
                let outerWidth = (outerPts.map { $0.x }.max() ?? 0) - (outerPts.map { $0.x }.min() ?? 0)
                
                if outerWidth > 0.01 {
                    let lipAspect = Double(outerHeight / outerWidth)
                    // Fuller lips → younger. Typical: 0.20-0.50
                    let lipAge = 18.0 + (1.0 - min(max((lipAspect - 0.20) / 0.30, 0.0), 1.0)) * 45.0
                    weightedSum += lipAge * 1.0
                    totalWeight += 1.0
                }
            }
        }
        
        // 3. Nose-to-mouth distance relative to face height (increases with age)
        if let nose = landmarks.nose,
           let innerLips = landmarks.innerLips,
           let faceContour = landmarks.faceContour {
            let nosePts = nose.normalizedPoints
            let lipPts = innerLips.normalizedPoints
            let jawPts = faceContour.normalizedPoints
            
            if !nosePts.isEmpty && !lipPts.isEmpty && !jawPts.isEmpty {
                let noseBottom = nosePts.map { $0.y }.min() ?? 0.5
                let mouthTop = lipPts.map { $0.y }.max() ?? 0.4
                let jawMinY = jawPts.map { $0.y }.min() ?? 0
                let jawMaxY = jawPts.map { $0.y }.max() ?? 1
                let faceHeight = jawMaxY - jawMinY
                
                if faceHeight > 0.05 {
                    let noseToMouth = Double(abs(noseBottom - mouthTop) / faceHeight)
                    // Larger gap → older. Typical: 0.03-0.13
                    let nmAge = 18.0 + min(max((noseToMouth - 0.03) / 0.10, 0.0), 1.0) * 50.0
                    weightedSum += nmAge * 1.2
                    totalWeight += 1.2
                }
            }
        }
        
        // 4. Forehead proportion (brow position relative to face top)
        if let leftBrow = landmarks.leftEyebrow,
           let rightBrow = landmarks.rightEyebrow,
           let faceContour = landmarks.faceContour {
            let leftBrowY = leftBrow.normalizedPoints.map { $0.y }.max() ?? 0.5
            let rightBrowY = rightBrow.normalizedPoints.map { $0.y }.max() ?? 0.5
            let browTopY = max(leftBrowY, rightBrowY)
            
            let jawPts = faceContour.normalizedPoints
            let jawMaxY = jawPts.map { $0.y }.max() ?? 1.0
            let jawMinY = jawPts.map { $0.y }.min() ?? 0.0
            let faceHeight = jawMaxY - jawMinY
            
            if faceHeight > 0.05 {
                let foreheadProportion = Double((jawMaxY - browTopY) / faceHeight)
                // Brow closer to top → more forehead → older
                let fhAge = 18.0 + (1.0 - min(max((foreheadProportion - 0.45) / 0.35, 0.0), 1.0)) * 45.0
                weightedSum += fhAge * 0.8
                totalWeight += 0.8
            }
        }
        
        if totalWeight > 0 {
            return min(max(weightedSum / totalWeight, 16.0), 75.0)
        }
        return 30.0
    }
    
    /// Aggregate biometric data for final submission
    func aggregateBiometricData() -> [String: Any]? {
        if state.biometricReadings.isEmpty { return nil }
        
        let readingsToUse = state.biometricReadings.suffix(10)
        let avgAge = readingsToUse.map { $0.age }.reduce(0, +) / Double(readingsToUse.count)
        
        var genderCounts: [String: Int] = [:]
        var totalConfidence = 0.0
        
        for reading in readingsToUse {
            genderCounts[reading.gender, default: 0] += 1
            totalConfidence += reading.confidence
        }
        
        let modeGender = genderCounts.max(by: { $0.value < $1.value })?.key ?? "unknown"
        let avgConfidence = totalConfidence / Double(readingsToUse.count)
        
        return [
            "avg_age": avgAge,
            "gender": modeGender,
            "gender_confidence": avgConfidence,
            "readings_count": readingsToUse.count,
        ]
    }
    
    // MARK: - Capture Failure
    
    /// Reset to detecting state after a capture failure
    func handleCaptureFailed() {
        state.captureState = .detectingFace
        state.statusMessage = "Capture failed. Please try again."
        state.isCameraCapturing = false
        state.onUIUpdateNeeded?()
    }
}
