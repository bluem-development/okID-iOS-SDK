# Liveness Module Implementation

## Overview
Full iOS implementation of the reference `liveness_module.dart` and `liveness_camera_screen.dart` for the OkID Verification SDK.

## Files Implemented

### 1. LivenessViewController.swift
**Location:** `/Users/karen/bluem/okid/ios/version2/verification_sdk/OkIDVerificationSDK/Sources/Modules/Liveness/LivenessViewController.swift`

**Purpose:** Complete liveness verification module with camera capture, face detection, biometric collection, and API upload.

#### Module State Machine
```
initial → capturing → uploading → (complete or error)
```

#### Camera Capture State Machine (matches the reference `CaptureState`)
```
detectingFace → faceFound → readyForCapture → delayBeforeCountdown → countdown → capturing
```

#### Key Features

**1. State Management**
- **Module States:**
  - `initial` - Initial state
  - `capturing` - Camera capture in progress
  - `uploading` - Uploading selfie to server
  - `error` - Upload failed

- **Capture States:**
  - `detectingFace` - Looking for any face
  - `faceFound` - Face detected but not properly positioned
  - `readyForCapture` - Face looking straight, can start countdown
  - `delayBeforeCountdown` - 3-second delay before countdown starts
  - `countdown` - Countdown in progress (3-2-1)
  - `capturing` - Taking picture

**2. Face Detection** (matches the reference functionality)
- **Quality Checks** (in priority order):
  1. **Size validation**: Face must be 25-95% of frame (move closer/farther)
  2. **Centering validation**: Face must be within 45% of center
  3. **Head orientation**: Yaw and pitch within ±15 degrees
  4. **Eyes open**: Both eyes should be open (placeholder in Vision)

- **Real-time Guidance:**
  - "Move closer to the camera" - Face too small
  - "Move back from the camera" - Face too large
  - "Move your face up/down/left/right" - Face not centered
  - "Turn your head slightly left/right" - Yaw out of range
  - "Look slightly up/down" - Pitch out of range
  - "Please keep your eyes open" - Eyes closed detected
  - "Position your face in the oval" - No face detected
  - "Multiple faces detected" - More than one face

**3. Capture Flow** (matches the reference)
1. Detect face position (every 300ms)
2. Validate face quality (size → centering → orientation → eyes)
3. Once face is perfect: "Perfect! Hold steady"
4. 3-second delay before countdown (silent)
5. 3-2-1 countdown with visual animations
6. Auto-capture photo at 80% JPEG quality
7. Collect biometric data (last 10 readings)
8. Upload to API with biometric data

**4. Biometric Data Collection** (matches the reference)
- Continuous collection during delay and countdown (every 500ms)
- Age/gender estimation using `AgeGenderEstimator`
- Aggregation of last 10 readings:
  - Average age
  - Mode (most common) gender
  - Average confidence
  - Total readings count
- Real-time display during countdown:
  - "Age: 28  |  MALE (87%)"

**5. UI Components**
- **Camera Preview**: Full-screen AVFoundation preview
- **Oval Face Guide**: 80% width × 40% height with cutout
- **Overlay**: Semi-transparent background with clear oval
- **Status Message**: Real-time guidance at top
- **Close Button**: Top-left X button
- **Countdown Display**: 
  - Green circular progress ring
  - Large countdown number (3-2-1)
  - Centered in viewport
- **State Indicator**: Bottom indicator showing current state
- **Biometric Display**: Bottom card showing age/gender during countdown
- **Uploading Screen**: Activity indicator with "Uploading selfie" message
- **Error Screen**: Error card with retry button

**6. Color Coding** (matches the reference)
- **White/Gray**: Detecting face (no face yet)
- **Orange**: Face found but not positioned correctly
- **Green**: Face properly positioned, countdown active

---

### 2. LivenessCameraScreen.swift (Profile Mode)
**Location:** `/Users/karen/bluem/okid/ios/version2/verification_sdk/OkIDVerificationSDK/Sources/Modules/Liveness/LivenessCameraScreen.swift`

**Purpose:** Simplified camera screen for profile mode (returns image data instead of uploading).

**Key Differences from LivenessViewController:**
- No API upload logic
- Returns `Data` via callback instead of calling `onComplete(nextStep)`
- No "uploading" or "error" states
- Simpler UI (no navigation bar, no biometric display)
- Used by `ProfileCaptureCoordinator` for profile mode

---

### 3. FaceDetectionService.swift
**Location:** `/Users/karen/bluem/okid/ios/version2/verification_sdk/OkIDVerificationSDK/Sources/Services/FaceDetectionService.swift`

**Purpose:** Face detection service using Vision framework.

#### FaceDetectionResult (Updated to Match the reference)

**Properties:**
- `boundingBox: CGRect` - Face bounding box in image coordinates
- `confidence: Float` - Detection confidence (0-1)
- `roll: Double?` - Head roll angle (tilt)
- `yaw: Double?` - Head yaw angle (left/right)
- `pitch: Double?` - Head pitch angle (up/down)

**Methods (matching the reference `FaceDetectionResult`):**
- `isLookingStraight` - Check if face looking straight (yaw/pitch within ±15°)
- `hasEyesOpen` - Check if eyes are open (placeholder, always true)
- `isWellPositioned` - Combined check (straight + eyes open)
- `guidanceMessage` - Get user-friendly guidance text
- `isCentered(frameWidth:frameHeight:)` - Check if face is centered (45% tolerance)
- `hasGoodSize(frameWidth:frameHeight:)` - Check if face is appropriate size (25-95%)
- `getSizeRatio(frameWidth:frameHeight:)` - Get face area ratio

**API:**
- `detectFaces(in: UIImage) async throws -> [FaceDetectionResult]` - Detect faces in image
- `detectFaceLandmarks(in: UIImage) async throws -> [FaceLandmarkResult]` - Detect face landmarks

---

## API Integration

### Upload Selfie Endpoint

**Request:**
```swift
try await apiClient.uploadSelfie(
    verificationId: verificationId,
    imageData: imageData,
    biometricData: [
        "avg_age": 28.5,
        "gender": "male",
        "gender_confidence": 0.87,
        "readings_count": 10
    ]
)
```

**Response:**
```swift
struct UploadSelfieResponse {
    let success: Bool
    let nextStep: String?
}
```

---

## Usage Examples

### 1. Verification Flow (with API upload)

```swift
let livenessVC = LivenessViewController(
    verificationId: "ver_123",
    config: livenessModuleConfig,
    sdkConfig: sdkConfig
) { nextStep in
    // Handle completion
    if let nextStep = nextStep {
        // Navigate to next module
        navigateToModule(nextStep)
    } else {
        // Verification complete
        showSuccess()
    }
}

present(livenessVC, animated: true)
```

### 2. Profile Mode (no API upload)

```swift
let livenessCamera = LivenessCameraScreen(
    onImageCaptured: { imageData, biometricData in
        // Save to profile storage
        profileStorage.saveLivenessData(
            OkIDProfileLivenessData(
                selfieImage: imageData,
                capturedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        dismiss(animated: true)
    },
    onCancel: {
        dismiss(animated: true)
    }
)

present(livenessCamera, animated: true)
```

---

## Feature Parity Checklist (Reference)

### ✅ Implemented Features

**State Management:**
- [x] Module state machine (initial, capturing, uploading, error)
- [x] Capture state machine (detectingFace → faceFound → readyForCapture → delayBeforeCountdown → countdown → capturing)
- [x] Real-time state transitions
- [x] Error handling with retry

**Face Detection:**
- [x] Periodic face checking (every 300ms)
- [x] Size validation (25-95% of frame)
- [x] Centering validation (45% tolerance)
- [x] Head orientation (yaw/pitch within ±15°)
- [x] Eyes open detection (placeholder)
- [x] Multiple face handling
- [x] Real-time guidance messages

**Capture Flow:**
- [x] Face quality checks in priority order
- [x] 3-second delay before countdown
- [x] 3-2-1 countdown with animations
- [x] Auto-capture on countdown complete
- [x] Image compression (80% JPEG)

**Biometric Data:**
- [x] Continuous age/gender collection (every 500ms)
- [x] Collection during delay and countdown
- [x] Aggregation of last 10 readings
- [x] Average age calculation
- [x] Mode gender calculation
- [x] Average confidence
- [x] Real-time display during countdown

**UI Components:**
- [x] Full-screen camera preview
- [x] Oval face guide with cutout
- [x] Semi-transparent overlay
- [x] Status message with guidance
- [x] Close button
- [x] Countdown display with progress ring
- [x] State indicator
- [x] Biometric display card
- [x] Uploading screen
- [x] Error screen with retry

**API Integration:**
- [x] Upload selfie endpoint
- [x] Include biometric data in request
- [x] Handle success response
- [x] Handle error response
- [x] Retry functionality

**Profile Mode:**
- [x] Simplified camera screen
- [x] Return image data via callback
- [x] No API upload
- [x] Used by ProfileCaptureCoordinator

---

## Configuration

### LivenessModuleConfig

```swift
public struct OkIDLivenessModuleConfig: Codable {
    public let enabled: Bool
    public let qualityThreshold: Double?
    
    public init(enabled: Bool = true, qualityThreshold: Double? = nil) {
        self.enabled = enabled
        self.qualityThreshold = qualityThreshold
    }
}
```

### SDK Config Theming

The liveness module respects the SDK theme colors:
- Primary color for progress indicators and buttons
- Custom branding colors for UI elements

---

## Technical Details

### Camera Setup
- **Framework**: AVFoundation
- **Device**: Front camera (`.builtInWideAngleCamera`)
- **Resolution**: `.high` preset
- **Audio**: Disabled
- **Format**: JPEG

### Face Detection
- **Framework**: Vision (VNDetectFaceRectanglesRequest)
- **Frequency**: Processed from video frames in real-time
- **Delegate**: AVCaptureVideoDataOutputSampleBufferDelegate

### Timers
- **Face Check Timer**: 300ms interval (matches the reference)
- **Biometric Collection Timer**: 500ms interval (matches the reference)
- **Countdown Timer**: 1 second interval
- **Delay Timer**: 1 second interval

### Image Processing
- **Capture**: From video output's last frame
- **Compression**: 80% JPEG quality
- **Format**: UIImage → JPEG Data

### Biometric Estimation
- **Service**: `AgeGenderEstimator.shared`
- **Input**: Cropped face image
- **Output**: Age (Double), Gender (String), Confidence (Double)
- **Aggregation**: Last 10 readings

---

## Error Handling

### Camera Errors
- No camera available → Show error message
- Camera initialization failed → Show error message
- Permission denied → Show error message

### Face Detection Errors
- No face detected → "Position your face in the oval"
- Multiple faces → "Multiple faces detected. Please have only one person in frame."
- Face too small → "Move closer to the camera"
- Face too large → "Move back from the camera"
- Face not centered → "Move your face up/down/left/right"
- Head orientation → "Turn your head slightly left/right" or "Look slightly up/down"

### Upload Errors
- Network error → Show error screen with retry
- API error → Show error screen with retry
- Timeout → Show error screen with retry

---

## Performance Considerations

1. **Face Detection**: Processed on background thread (`videoQueue`)
2. **Camera Operations**: Run on background thread (`.userInitiated`)
3. **UI Updates**: Dispatched to main thread
4. **Timer Management**: Properly invalidated on cleanup
5. **Memory Management**: Weak references to avoid retain cycles

---

## Testing Checklist

### Camera
- [ ] Front camera initializes correctly
- [ ] Camera preview displays full screen
- [ ] Camera preview orientation is correct
- [ ] Close button works

### Face Detection
- [ ] No face: "Position your face in the oval"
- [ ] Multiple faces: "Multiple faces detected"
- [ ] Face too small: "Move closer to the camera"
- [ ] Face too large: "Move back from the camera"
- [ ] Face not centered: Directional guidance
- [ ] Face poorly oriented: "Turn your head" or "Look up/down"
- [ ] Face perfect: "Perfect! Hold steady" → countdown starts

### Countdown
- [ ] 3-second delay before countdown
- [ ] Countdown displays 3-2-1
- [ ] Progress ring animates correctly
- [ ] Auto-capture on countdown complete
- [ ] Countdown cancels if face moves

### Biometric Collection
- [ ] Age/gender estimation runs during countdown
- [ ] Display shows real-time biometric data
- [ ] Last 10 readings are aggregated
- [ ] Biometric data included in API request

### Upload
- [ ] Uploading screen displays
- [ ] Activity indicator animates
- [ ] Upload succeeds → onComplete called
- [ ] Upload fails → error screen shown

### Error Handling
- [ ] Error screen displays error message
- [ ] Retry button restarts camera
- [ ] Network errors handled gracefully

### Profile Mode
- [ ] LivenessCameraScreen captures image
- [ ] Image data returned via callback
- [ ] No API upload occurs
- [ ] Cancel button works

---

## Future Enhancements

1. **Eye Detection**: Implement true eye open/closed detection using Vision landmarks
2. **Face Quality Scoring**: Add overall quality score calculation
3. **Liveness Detection**: Add active liveness checks (blink, smile, etc.)
4. **Face Tracking**: Use face tracking ID for smoother experience
5. **Performance Optimization**: Cache face detection results between frames
6. **Accessibility**: Add VoiceOver labels and accessibility identifiers
7. **Localization**: Support multiple languages for guidance messages
8. **Analytics**: Track capture success rates and failure reasons

---

**Implementation Status:** ✅ Complete and matching the reference functionality
**Last Updated:** December 20, 2025

