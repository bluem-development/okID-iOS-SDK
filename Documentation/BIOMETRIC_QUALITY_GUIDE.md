# Biometric Analysis & Quality Validation Guide

Complete guide for Age/Gender Estimation and Document Quality features in OkID iOS SDK.

## Table of Contents

1. [Age/Gender Estimation](#agegender-estimation)
2. [Document Quality Validation](#document-quality-validation)
3. [Integration Examples](#integration-examples)
4. [CoreML Model Integration](#coreml-model-integration)
5. [Performance Optimization](#performance-optimization)

---

## Age/Gender Estimation

### Overview

The `AgeGenderEstimator` service provides on-device biometric analysis using CoreML for privacy and performance.

### Features

- ✅ Age estimation (18-80 years range)
- ✅ Gender classification (male/female)
- ✅ Confidence scoring
- ✅ On-device processing (no server calls)
- ✅ Privacy-preserving
- ✅ CoreML-ready architecture

### Basic Usage

```swift
import OkIDVerificationSDK

let estimator = AgeGenderEstimator.shared

// Initialize (one-time)
try await estimator.initialize()

// Estimate from face image
let result = try await estimator.estimate(faceImage: selfieImage)

print("Age: \(result.age) years")
print("Gender: \(result.gender)")
print("Confidence: \(result.genderConfidence)")
```

### Automatic Integration

Age/gender estimation is automatically performed during liveness verification:

```swift
// Liveness module auto-includes biometric data
await OkIDVerificationSDK.shared.startVerification(
    verificationId: "ver_xxx",
    config: config,
    from: viewController
)

// Biometric metadata automatically added:
// {
//   "estimated_age": 32.5,
//   "estimated_gender": "male",
//   "gender_confidence": 0.87
// }
```

### Result Structure

```swift
public struct AgeGenderResult {
    public let age: Double              // Estimated age (18-80)
    public let gender: String           // "male" or "female"
    public let genderConfidence: Double // 0.0 to 1.0
}
```

### Input Requirements

- **Image Format**: UIImage
- **Recommended Size**: 64x64 minimum (auto-resized)
- **Content**: Cropped face region
- **Quality**: Well-lit, clear face
- **Orientation**: Face-forward (not profile)

### Error Handling

```swift
do {
    let result = try await estimator.estimate(faceImage: image)
} catch AgeGenderError.modelNotInitialized {
    print("Call initialize() first")
} catch AgeGenderError.preprocessingFailed {
    print("Invalid image format")
} catch AgeGenderError.inferenceFailed {
    print("Model inference error")
}
```

---

## Document Quality Validation

### Overview

The `DocumentProcessor` service validates document image quality before upload, reducing rejections and improving accuracy.

### Features

- ✅ Blur detection (Laplacian variance)
- ✅ Glare detection (brightness thresholding)
- ✅ Document centering check
- ✅ Size validation (area ratio)
- ✅ Boundary detection (Vision framework)
- ✅ Real-time feedback support

### Basic Usage

```swift
import OkIDVerificationSDK

let processor = DocumentProcessor.shared

// Initialize
await processor.initialize()

// Analyze document
let quality = try await processor.processDocument(image: documentImage)

if quality.isGoodQuality {
    print("✓ Document quality: Excellent")
    // Proceed with upload
} else {
    print("Issues: \(quality.qualityDescription)")
    // Show user feedback
}
```

### Quality Metrics

```swift
public struct DocumentQualityResult {
    public let blurScore: Double        // Higher = sharper (threshold: 150)
    public let isBlurry: Bool           // true if too blurry
    public let isCentered: Bool         // true if well-centered
    public let hasGoodSize: Bool        // true if proper size
    public let hasGlare: Bool           // true if glare detected
    public let confidence: Double       // 0.0 to 1.0
    
    public var isGoodQuality: Bool      // All checks pass
    public var qualityDescription: String // Human-readable
}
```

### Individual Checks

#### 1. Blur Detection

```swift
let quality = try await processor.processDocument(image: image)

if quality.isBlurry {
    print("Blur score: \(quality.blurScore) (threshold: 150)")
    showAlert("Image too blurry. Use better lighting and hold steady.")
}
```

**Algorithm**: Laplacian variance
- Score < 150: Blurry
- Score 150-200: Acceptable
- Score > 200: Sharp

#### 2. Glare Detection

```swift
let hasGlare = try await processor.hasGlare(image: image)

if hasGlare {
    showAlert("Glare detected. Adjust lighting or tilt document.")
}
```

**Algorithm**: Brightness thresholding
- Analyzes pixel brightness (0-255)
- Glare if >5% pixels above 240
- Configurable via `glareThreshold` property

#### 3. Boundary Detection

```swift
let boundaries = try await processor.detectDocumentBoundaries(image: image)

if let bounds = boundaries {
    print("Top-left: \(bounds.topLeft)")
    print("Area: \(bounds.area) px²")
    print("Center: \(bounds.center)")
    print("Confidence: \(bounds.confidence)")
}
```

**Uses**: Vision framework `VNDetectRectanglesRequest`
- Detects rectangular shapes
- Returns corner coordinates
- Confidence scoring

#### 4. Centering Check

```swift
let isCentered = processor.isDocumentCentered(
    boundaries: bounds,
    imageSize: image.size
)

if !isCentered {
    showAlert("Center the document in frame.")
}
```

**Algorithm**: Distance from center
- Calculates document center vs image center
- Centered if within 20% deviation

#### 5. Size Validation

```swift
let hasGoodSize = processor.hasGoodSize(
    boundaries: bounds,
    imageSize: image.size
)

if !hasGoodSize {
    showAlert("Move closer to fill the frame.")
}
```

**Algorithm**: Area ratio analysis
- Document area / Image area
- Good size: 30% - 90%
- Configurable via properties

### Configuration

```swift
// Customize thresholds
processor.blurThreshold = 180.0      // Default: 150.0
processor.minAreaRatio = 0.4         // Default: 0.3
processor.maxAreaRatio = 0.85        // Default: 0.9
processor.glareThreshold = 230.0     // Default: 240.0
```

### Automatic Integration

Document quality is automatically checked in the Document module:

```swift
// Document module auto-validates before upload
await OkIDVerificationSDK.shared.startVerification(...)

// Automatic checks:
// 1. Blur detection
// 2. Glare detection
// 3. Quality validation
// 4. User feedback if issues found
```

---

## Integration Examples

### Example 1: Real-time Camera Feedback

```swift
class DocumentCameraViewController: UIViewController {
    
    let processor = DocumentProcessor.shared
    var feedbackLabel: UILabel!
    
    func processCameraFrame(_ image: UIImage) {
        Task {
            do {
                let quality = try await processor.processDocument(image: image)
                
                await MainActor.run {
                    if quality.isBlurry {
                        feedbackLabel.text = "⚠ Hold steady"
                        feedbackLabel.textColor = .orange
                    } else if quality.hasGlare {
                        feedbackLabel.text = "⚠ Reduce glare"
                        feedbackLabel.textColor = .orange
                    } else if !quality.isCentered {
                        feedbackLabel.text = "⚠ Center document"
                        feedbackLabel.textColor = .orange
                    } else if !quality.hasGoodSize {
                        feedbackLabel.text = "⚠ Move closer"
                        feedbackLabel.textColor = .orange
                    } else {
                        feedbackLabel.text = "✓ Perfect - Tap to capture"
                        feedbackLabel.textColor = .green
                        // Enable capture button
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

### Example 2: Pre-upload Validation

```swift
func validateBeforeUpload(image: UIImage) async -> Bool {
    let processor = DocumentProcessor.shared
    
    do {
        let quality = try await processor.processDocument(image: image)
        
        // Check quality
        guard quality.blurScore >= 150 else {
            showAlert("Image too blurry. Retake photo.")
            return false
        }
        
        guard !quality.hasGlare else {
            showAlert("Glare detected. Adjust lighting.")
            return false
        }
        
        // All checks passed
        return true
        
    } catch {
        showAlert("Validation failed: \(error)")
        return false
    }
}
```

### Example 3: Biometric Enrichment

```swift
func captureSelfieWithBiometrics() async {
    let faceDetector = FaceDetectionService.shared
    let estimator = AgeGenderEstimator.shared
    
    // Capture selfie
    let selfieImage = captureSelfie()
    
    // Detect face
    let faces = try? await faceDetector.detectFaces(in: selfieImage)
    
    guard let face = faces?.first else {
        showAlert("No face detected")
        return
    }
    
    // Estimate age/gender
    let biometrics = try? await estimator.estimate(faceImage: selfieImage)
    
    // Build metadata
    var metadata: [String: Any] = [
        "face_detected": true,
        "confidence": face.confidence
    ]
    
    if let bio = biometrics {
        metadata["estimated_age"] = bio.age
        metadata["estimated_gender"] = bio.gender
        metadata["gender_confidence"] = bio.genderConfidence
    }
    
    // Upload with enriched metadata
    await uploadSelfie(image: selfieImage, metadata: metadata)
}
```

---

## CoreML Model Integration

### Age/Gender Model

The SDK supports custom CoreML models for production use.

#### Model Requirements

- **Input**: 64x64x3 RGB image tensor
- **Outputs**: 
  - Age: Float scalar
  - Gender: 2-element probability array [male, female]

#### Model Integration Steps

1. **Train or obtain model** (TensorFlow/PyTorch)
2. **Convert to CoreML**:

```python
import coremltools as ct

# Convert model
coreml_model = ct.convert(
    model,
    inputs=[ct.ImageType(
        name="input",
        shape=(1, 64, 64, 3),
        scale=1.0/255.0  # Normalize to [0,1]
    )],
    outputs=[
        ct.TensorType(name="age"),
        ct.TensorType(name="gender")
    ]
)

# Save
coreml_model.save("AgeGenderModel.mlmodel")
```

3. **Add to Xcode project**
4. **Update AgeGenderEstimator.swift**:

```swift
let configuration = MLModelConfiguration()
let mlModel = try await AgeGenderModel.load(configuration: configuration)
self.model = try VNCoreMLModel(for: mlModel.model)
```

#### Recommended Models

- **face-api.js AgeGenderNet**: Pre-trained, good accuracy
- **UTKFace models**: Large dataset, diverse demographics
- **Custom trained**: Best for your specific use case

### Document Detection Model

For advanced document detection, integrate YOLO or similar.

#### Model Requirements

- **Input**: Variable size image
- **Output**: Bounding boxes + class scores

#### Integration Example

```swift
let configuration = MLModelConfiguration()
let mlModel = try await DocumentDetector.load(configuration: configuration)
let visionModel = try VNCoreMLModel(for: mlModel.model)

let request = VNCoreMLRequest(model: visionModel) { request, error in
    guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
    // Process detections
}
```

---

## Performance Optimization

### Benchmarks

| Operation | Duration | Notes |
|-----------|----------|-------|
| Face Detection | ~50ms | Vision framework |
| Age/Gender Estimation | ~100ms | CoreML on-device |
| Blur Detection | ~150ms | CPU-intensive |
| Boundary Detection | ~80ms | Vision framework |
| Glare Detection | ~100ms | Pixel analysis |

### Optimization Tips

#### 1. Image Resolution

```swift
// Resize large images before processing
let maxDimension: CGFloat = 1920
let resized = image.resized(maxDimension: maxDimension)

// Process resized image
let quality = try await processor.processDocument(image: resized)
```

#### 2. Async Processing

```swift
// Process in parallel
async let faceTask = faceDetector.detectFaces(in: image)
async let qualityTask = processor.processDocument(image: image)

let (faces, quality) = await (try? faceTask, try? qualityTask)
```

#### 3. Caching

```swift
// Cache processor instances
class CameraViewController {
    let processor = DocumentProcessor.shared  // Singleton
    
    override func viewDidLoad() {
        Task {
            await processor.initialize()  // Once
        }
    }
}
```

#### 4. Throttling

```swift
// Throttle real-time checks
var lastProcessTime: Date?
let throttleInterval: TimeInterval = 0.5  // 500ms

func processCameraFrame(_ image: UIImage) {
    let now = Date()
    
    if let last = lastProcessTime, now.timeIntervalSince(last) < throttleInterval {
        return  // Skip this frame
    }
    
    lastProcessTime = now
    
    Task {
        let quality = try await processor.processDocument(image: image)
        // Update UI
    }
}
```

---

## Best Practices

### Age/Gender Estimation

✅ **Do:**
- Use well-lit, clear face images
- Crop to face region before estimating
- Initialize once, reuse instance
- Handle estimation errors gracefully
- Include confidence in decisions

❌ **Don't:**
- Estimate from profile/partial faces
- Use very low resolution images
- Make critical decisions on low confidence
- Estimate multiple times per image

### Document Quality

✅ **Do:**
- Check quality before upload
- Provide real-time feedback
- Configure thresholds for your use case
- Test with diverse document types
- Log quality metrics for analysis

❌ **Don't:**
- Skip quality checks
- Use overly strict thresholds
- Process every frame without throttling
- Ignore individual quality metrics
- Upload poor quality images

---

## Troubleshooting

### Age/Gender Issues

**Problem**: Inaccurate estimates
- **Solution**: Ensure face is well-lit and frontal
- **Solution**: Use higher resolution images
- **Solution**: Train custom model for your demographic

**Problem**: Slow performance
- **Solution**: Resize images to 64x64 before processing
- **Solution**: Use CoreML model instead of mock
- **Solution**: Process on background thread

### Document Quality Issues

**Problem**: False blur detection
- **Solution**: Adjust `blurThreshold` (lower for more lenient)
- **Solution**: Check image compression settings
- **Solution**: Ensure adequate lighting

**Problem**: Glare not detected
- **Solution**: Lower `glareThreshold` (230 vs 240)
- **Solution**: Check for overexposed regions
- **Solution**: Use histogram analysis

**Problem**: Boundary detection fails
- **Solution**: Ensure good contrast with background
- **Solution**: Check for document edges visibility
- **Solution**: Adjust Vision framework parameters

---

## Summary

The OkID iOS SDK provides comprehensive biometric analysis and quality validation:

- **Age/Gender Estimation**: On-device, privacy-preserving, CoreML-ready
- **Document Quality**: Multi-faceted validation (blur, glare, boundaries)
- **Automatic Integration**: Works out-of-the-box with verification flow
- **Customizable**: Adjust thresholds and behavior
- **Production-Ready**: Performance optimized, error handled

For support: support@okid.com  
Documentation: https://docs.okid.com

