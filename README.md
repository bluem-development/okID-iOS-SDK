# OkID Verification SDK for iOS

Pure native iOS SDK for identity verification with async/await support. Provides document capture, liveness detection, NFC passport reading, QR code scanning, and profile management.

## Features

- **Document Verification**: Capture and verify identity documents (passport, ID card, driver's license)
- **Liveness Detection**: Selfie capture with face detection
- **NFC Reading**: Extract data from ePassport chips
- **QR Code Integration**: Scan QR codes from v2client portal for seamless verification
- **Profile Management**: Store and reuse verification data securely
- **Async/Await**: Modern Swift concurrency for cleaner code
- **Customizable UI**: Theme configuration with colors, typography, and branding
- **Secure Storage**: Encrypted profile storage using Keychain

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Getting Started

- Read this README doc
- Read the [Quick Start section](#quick-start)
- Try the example by downloading the project from GitHub
- Read the [Installation Guide](#installation)
- Check the [Documentation](Documentation/) for detailed guides
- Read the [Error Handling Guide](Documentation/ERROR_HANDLING_GUIDE.md)

## Installation

There are 4 ways to use OkID Verification SDK in your project:
- using CocoaPods
- using Carthage
- using Swift Package Manager
- manual installation (build frameworks or embed Xcode Project)

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C and Swift, which automates and simplifies the process of using 3rd-party libraries in your projects. See the [Get Started](http://cocoapods.org/#get_started) section for more details.

#### Podfile

```ruby
platform :ios, '15.0'
pod 'OkIDVerificationSDK', '~> 1.0'
```

#### Swift and static framework

Swift projects can use `use_frameworks!` to make all Pods into dynamic frameworks:

```ruby
platform :ios, '15.0'
use_frameworks!
pod 'OkIDVerificationSDK'
```

Starting with `CocoaPods 1.5.0+` (with `Xcode 9+`), you can also use modular headers to build as a static framework without `use_frameworks!`:

```ruby
platform :ios, '15.0'
# Uncomment the next line when you want all Pods as static framework
# use_modular_headers!
pod 'OkIDVerificationSDK', :modular_headers => true
```

Then run:

```bash
pod install
```

### Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a lightweight dependency manager for Swift and Objective-C. It leverages CocoaTouch modules and is less invasive than CocoaPods.

To install with Carthage, follow the instruction on [Carthage](https://github.com/Carthage/Carthage).

#### Cartfile

Make the following entry in your `Cartfile`:

```
github "okid/okid-verification-sdk-ios" ~> 1.0.0
```

#### Build with XCFrameworks (Recommended)

```bash
carthage update --use-xcframeworks --platform iOS
```

#### Traditional Carthage build

```bash
carthage update --platform iOS
```

If this is your first time using Carthage in the project, you'll need to go through some additional steps as explained [over at Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

> **Note**: Carthage does not codesign the built frameworks by default. You may need to sign the frameworks yourself with your Apple Developer Program identity before submitting to the App Store.

### Installation with Swift Package Manager (Xcode 11+)

[Swift Package Manager](https://swift.org/package-manager/) (SwiftPM) is a tool for managing the distribution of Swift code as well as C-family dependencies. From Xcode 11, SwiftPM got natively integrated with Xcode.

OkID Verification SDK supports SwiftPM from version 1.0.0. To use SwiftPM, you should use Xcode 11+ to open your project. 

#### Using Xcode UI

1. Click `File` -> `Swift Packages` -> `Add Package Dependency` (or `Add Package` in Xcode 13+)
2. Enter the OkID Verification SDK repo URL: `https://github.com/okid/okid-verification-sdk-ios.git`
3. Select the version or branch you want to use
4. Choose the target where you want to add the package

After selecting the package, you can choose the dependency type (tagged version, branch or commit). Then Xcode will setup all the dependencies for you.

#### Using Package.swift

If you're a framework author and use OkID Verification SDK as a dependency, update your `Package.swift` file:

```swift
let package = Package(
    name: "YourPackage",
    dependencies: [
        .package(url: "https://github.com/okid/okid-verification-sdk-ios.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: ["OkIDVerificationSDK"]
        )
    ]
)
```

### Import headers in your source files

In the source files where you need to use the library, import the header:

#### Objective-C

```objective-c
#import <OkIDVerificationSDK/OkIDVerificationSDK.h>
```

It's also recommended to use the module import syntax, available for CocoaPods (enable `modular_headers`), Carthage, and SwiftPM:

```objective-c
@import OkIDVerificationSDK;
```

#### Swift

```swift
import OkIDVerificationSDK
```

### Manual Installation

For manual installation, you can directly add the SDK source files to your project or build it as a framework.

#### Option 1: Add Source Files Directly

1. Download or clone the OkID Verification SDK repository
2. Drag the `Sources` folder into your Xcode project
3. Make sure "Copy items if needed" is checked
4. Add the folder to your target
5. Ensure all source files are included in your target's "Compile Sources" build phase

#### Option 2: Build as Framework

##### Step 1: Clone the repository

```bash
git clone https://github.com/okid/okid-verification-sdk-ios.git
cd okid-verification-sdk-ios
```

##### Step 2: Open the project in Xcode

Since the SDK uses Swift Package Manager structure, you can create a framework target or use Xcode's built-in archive:

1. Open the project folder in Xcode
2. Go to File > New > Project
3. Select "Framework" under iOS
4. Add the SDK sources to the framework target
5. Build the framework for your desired architectures

##### Step 3: Build for multiple architectures

To create a universal framework that works on both simulators and devices:

```bash
# Build for iOS devices (ARM64)
xcodebuild archive \
  -scheme OkIDVerificationSDK \
  -archivePath ./build/ios.xcarchive \
  -sdk iphoneos \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator (ARM64 + x86_64)
xcodebuild archive \
  -scheme OkIDVerificationSDK \
  -archivePath ./build/ios-simulator.xcarchive \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
```

##### Step 4: Create XCFramework

Combine the archives into a single XCFramework:

```bash
xcodebuild -create-xcframework \
  -framework ./build/ios.xcarchive/Products/Library/Frameworks/OkIDVerificationSDK.framework \
  -framework ./build/ios-simulator.xcarchive/Products/Library/Frameworks/OkIDVerificationSDK.framework \
  -output ./build/OkIDVerificationSDK.xcframework
```

##### Step 5: Add to Your Project

1. Drag `OkIDVerificationSDK.xcframework` into your Xcode project
2. In your target's "Frameworks, Libraries, and Embedded Content", ensure it's set to "Embed & Sign"
3. The framework is now ready to use

#### Option 3: Embed Xcode Project

You can also add the SDK as a subproject:

1. Download or clone the repository
2. Drag `OkIDVerificationSDK` folder into your Xcode project's Project Navigator
3. In your app target's settings:
   - Go to "General" > "Frameworks, Libraries, and Embedded Content"
   - Click "+" and add `OkIDVerificationSDK.framework`
   - Set it to "Embed & Sign"
4. In "Build Phases" > "Target Dependencies", add `OkIDVerificationSDK`

#### Important Notes for Manual Installation

- **Resources**: Make sure to include the `Sources/Resources` folder, especially the `yolo12n.mlpackage` CoreML model
- **Frameworks**: The SDK requires the following frameworks:
  - `UIKit`
  - `AVFoundation`
  - `CoreML`
  - `Vision`
  - `CoreNFC`
  - `Security`
- **Swift Version**: Ensure your project uses Swift 5.7 or later
- **Deployment Target**: Set your minimum deployment target to iOS 15.0+

## Configuration

### Required Info.plist Entries

Add the following keys to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for document and selfie capture</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to save captured images</string>

<key>NFCReaderUsageDescription</key>
<string>NFC access is required to read passport data</string>

<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
    <string>A0000002472001</string>
</array>
```

### Required Capabilities

Enable the following capabilities in your Xcode project:

1. **Near Field Communication Tag Reading**
   - Target > Signing & Capabilities > + Capability > Near Field Communication Tag Reading

2. **Camera Usage**
   - Automatically enabled when you add camera usage description

### Entitlements

Add `com.apple.developer.nfc.readersession.formats` to your entitlements file:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
```

## Logging

The SDK includes a built-in logger with configurable log levels. By default, only **errors** are printed to keep the console clean.

### Log Levels

| Level | Description |
|-------|-------------|
| `.debug` | Verbose diagnostic output (frame processing, detection state, feature values) |
| `.info` | Key lifecycle events (model loaded, camera started, module completed) |
| `.warning` | Non-fatal issues (fallback paths, missing optional resources) |
| `.error` | Failures that affect functionality (model load failure, API errors) |

### Setting the Log Level

Set `Logger.minimumLevel` early in your app (e.g., in `AppDelegate` or before starting verification). Only messages at or above the minimum level are printed.

```swift
import OkIDVerificationSDK

// During development — see all logs
Logger.minimumLevel = .debug

// For QA / staging — skip verbose debug output
Logger.minimumLevel = .info

// Production default — errors only
Logger.minimumLevel = .error
```

### Disabling Logging Entirely

Logging is automatically disabled in release builds. To disable it in debug builds as well:

```swift
Logger.isEnabled = false
```

## Quick Start

### 1. Configure the SDK

```swift
import OkIDVerificationSDK

let config = OkIDSDKConfig(
    baseUrl: "https://api.okid.com",
    timeout: 30,
    retryAttempts: 3,
    theme: .defaultTheme
)
```

### 2. Start Verification

```swift
// Simple verification
await OkIDVerificationSDK.shared.startVerification(
    verificationId: "your-verification-id",
    config: config,
    from: viewController
)

// With result callback
let result = await OkIDVerificationSDK.shared.startVerificationForResult(
    verificationId: "your-verification-id",
    config: config,
    from: viewController
)

if let result = result {
    print("Status: \\(result.status)")
    if result.isSuccess {
        print("Verification successful!")
    }
}
```

### 3. QR Code Flow

```swift
// Start verification from QR code
let result = await OkIDVerificationSDK.shared.startFromQRCode(
    from: viewController,
    config: config
)
```

### 4. Profile Management

```swift
// Check profile status
let status = await OkIDVerificationSDK.shared.getProfileStatus()
print("Has fresh data: \\(status.hasAnyFreshData)")

// Open profile dashboard
let profileResult = await OkIDVerificationSDK.shared.manageProfile(
    from: viewController,
    config: config
)

// Delete profile
await OkIDVerificationSDK.shared.deleteProfile()
```

## Advanced Usage

### Custom Theme

```swift
let customTheme = OkIDThemeConfig(
    colors: OkIDColorPalette(
        primary: UIColor(rgb: 0x4ECDC4),
        secondary: UIColor(rgb: 0x6c757d),
        accent: UIColor(rgb: 0x10b981),
        warning: UIColor(rgb: 0xfbbf24),
        error: UIColor(rgb: 0xef4444),
        background: .white,
        surface: UIColor(rgb: 0xf8f9fa),
        text: UIColor(rgb: 0x1a1a1a),
        textSecondary: UIColor(rgb: 0x6c757d),
        border: UIColor(rgb: 0xe5e7eb)
    ),
    typography: .defaultConfig,
    spacing: .defaultConfig,
    branding: OkIDBrandingConfig(
        organizationName: "My Company",
        logoImage: UIImage(named: "logo"),
        primaryColor: UIColor(rgb: 0x4ECDC4),
        secondaryColor: UIColor(rgb: 0x6c757d)
    ),
    borderRadius: .defaultConfig
)

let config = OkIDSDKConfig(
    baseUrl: "https://api.okid.com",
    theme: customTheme
)
```

### Verification Callbacks

```swift
class MyCallbacks: OkIDVerificationCallbacks {
    func onModuleComplete(module: String, status: String) {
        print("Module \\(module) completed with status: \\(status)")
    }
    
    func onVerificationComplete(result: OkIDVerificationResult) {
        print("Verification complete: \\(result.status)")
    }
    
    func onError(error: String) {
        print("Error: \\(error)")
    }
    
    func onCancel() {
        print("User cancelled")
    }
}

let callbacks = MyCallbacks()

await OkIDVerificationSDK.shared.startVerification(
    verificationId: "verification-id",
    config: config,
    from: viewController,
    callbacks: callbacks
)
```

### Custom Flow Order

```swift
let customFlow = ["terms", "liveness", "document", "validation"]
let customModules: [String: Any] = [
    "document": [
        "quality_threshold": 8.0,
        "read_nfc_from_passport": true
    ],
    "liveness": [
        "mode": "passive",
        "threshold": 0.9
    ]
]

await OkIDVerificationSDK.shared.startVerification(
    verificationId: "verification-id",
    config: config,
    from: viewController,
    flow: customFlow,
    modules: customModules
)
```

## Permissions

### Info.plist

Add the following to your `Info.plist`:

```xml
<!-- Camera access -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture document and selfie photos</string>

<!-- NFC access (for ePassport reading) -->
<key>NFCReaderUsageDescription</key>
<string>NFC access is required to read passport chip data</string>
```

### NFC Entitlements (Required for ePassport Reading)

Add an entitlements file to your **app target** with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- NFC Tag Reading Capability -->
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>TAG</string>
    </array>
    
    <!-- ISO7816 Application Identifiers for Passport Reading -->
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>A0000002472001</string>
    </array>
</dict>
</plist>
```

**Important Notes:**
- NFC only works on **physical devices** with NFC capability (iPhone 7 and later)
- NFC does **not work** on the iOS Simulator
- Entitlements must be added to your **app target**, not just the SDK
- Enable "Near Field Communication Tag Reading" capability in your app target settings

## Architecture

### Core Components

- **OkIDVerificationSDK**: Main SDK class and entry point
- **VerificationFlowController**: Manages verification flow and module navigation
- **ProfileStorageService**: Secure profile storage with Keychain
- **VerificationAPIClient**: Backend API communication

### Modules

- **Terms**: Terms and conditions acceptance
- **Document**: Document capture and verification
- **Liveness**: Selfie capture with face detection
- **NFC**: ePassport chip reading
- **FormData**: Additional data collection
- **Validation**: Final verification and results
- **QRScanner**: QR code scanning for portal integration
- **Profile**: Profile management dashboard

### Services

- **FaceDetectionService**: Face detection using Vision framework
- **AgeGenderEstimator**: Age and gender estimation from face images
- **DocumentProcessor**: Document quality validation (blur, glare, centering)
- **NFCPassportReaderService**: NFC passport reading (PACE/BAC)
- **DG2Parser**: Biometric data extraction from ePassport Data Group 2
- **ImageDecoderService**: JPEG2000 and image format decoding
- **MRZParser**: Machine Readable Zone parsing and validation
- **MRZTracker**: Cross-frame MRZ detection confidence tracking
- **BlurDetection**: Image quality assessment (Laplacian variance)
- **DesktopNotifier**: Server-sent events for desktop sync
- **QRURLParser**: QR code URL parsing

## Models

All data models include full `Codable` support:

- **OkIDVerificationResult**: Verification result
- **OkIDVerificationConfig**: Verification configuration
- **OkIDDocumentModuleResponse**: Document upload response
- **OkIDModuleCompletionResponse**: Module completion
- **OkIDProfileStatus**: Profile status and freshness
- **OkIDPassportData**: NFC passport data
- **OkIDQRScanResult**: QR scan result

## Error Handling

The SDK provides a comprehensive error handling system with user-friendly messages, recovery suggestions, and automatic error normalization.

### OkIDError

All errors are represented by the `OkIDError` enum with 60+ specific cases organized by category:

```swift
// Network errors
case networkUnavailable
case requestTimeout
case serverError(statusCode: Int, message: String?)
case rateLimitExceeded(retryAfter: TimeInterval?)

// Document errors
case documentBlurry(score: Double, threshold: Double)
case documentNotDetected
case glareDetected

// Liveness errors
case faceNotDetected
case multipleFacesDetected
case poorLighting

// NFC errors
case nfcTagConnectionLost
case nfcInvalidCredentials
case nfcTimeout

// Camera errors
case cameraPermissionDenied
case cameraNotAvailable

// Storage errors
case storageQuotaExceeded
case dataCorrupted

// And many more...
```

### Basic Error Handling

```swift
do {
    let result = try await apiClient.uploadDocument(...)
} catch {
    // Normalize any error to OkIDError
    let okidError = OkIDErrorHandler.shared.normalize(error)
    
    // Log with context
    OkIDErrorHandler.shared.handle(
        error,
        context: "Document upload",
        severity: .error
    )
    
    // Access error properties
    print(okidError.errorDescription)        // User-friendly message
    print(okidError.recoverySuggestion)      // Recovery guidance
    print(okidError.category)                // .document
    print(okidError.isRecoverable)           // true/false
    print(okidError.requiresUserAction)      // true/false
}
```

### Presenting Errors to Users

```swift
do {
    try await someOperation()
} catch {
    let okidError = OkIDErrorHandler.shared.normalize(error)
    
    // Present error with automatic retry logic
    await OkIDErrorHandler.shared.presentError(
        error,
        from: self,
        onRetry: okidError.isRecoverable ? {
            Task { await self.retryOperation() }
        } : nil,
        onDismiss: {
            self.handleDismiss()
        }
    )
}
```

### Error Properties

Every `OkIDError` provides:

```swift
let error = OkIDError.documentBlurry(score: 50, threshold: 100)

// User-friendly description
print(error.errorDescription)
// "Document image is too blurry (score: 50, required: 100). Please take a clearer photo."

// Recovery suggestion
print(error.recoverySuggestion)
// "Take a new photo ensuring good lighting and focus."

// Error category
print(error.category)
// .document

// Recoverability
if error.isRecoverable {
    // Show retry button
}

// User action required
if error.requiresUserAction {
    // Guide user to Settings
}
```

### Error Categories

Errors are organized into categories for better handling:

- **Network**: Connection issues, timeouts, server errors
- **Authentication**: Unauthorized, expired sessions
- **Validation**: Verification not found, expired, invalid state
- **Document**: Blur, glare, format issues
- **Liveness**: Face detection, positioning issues
- **NFC**: Connection lost, invalid credentials, timeout
- **QR Code**: Invalid URL, unsupported origin
- **Camera**: Permission denied, not available
- **Storage**: Write/read failures, quota exceeded
- **Form**: Invalid data, missing fields
- **Processing**: Image/face/biometric processing failures
- **Configuration**: Invalid setup, missing keys
- **User Action**: Cancelled, manual intervention needed

### Recovery Strategies

Handle recoverable errors with retry logic:

```swift
func uploadDocument() async {
    do {
        try await apiClient.uploadDocument(...)
    } catch {
        let okidError = OkIDErrorHandler.shared.normalize(error)
        
        if okidError.isRecoverable {
            // Show retry option for recoverable errors
            await OkIDErrorHandler.shared.presentError(
                error,
                from: self,
                onRetry: {
                    Task { await self.uploadDocument() }
                }
            )
        } else {
            // Show error without retry
            await OkIDErrorHandler.shared.presentError(
                error,
                from: self
            )
        }
    }
}
```

### Error Listening

Add global error listeners for analytics:

```swift
OkIDErrorHandler.shared.addErrorListener { error in
    // Track in analytics
    Analytics.logError(
        category: error.category.rawValue,
        message: error.errorDescription ?? "Unknown",
        recoverable: error.isRecoverable
    )
}
```

### Automatic Conversion

Legacy error types are automatically converted:

```swift
// Old errors automatically become OkIDError
catch let error as OkIDAPIError {
    // Automatically converted to OkIDError
}

catch let error as OkIDNFCReadError {
    // Automatically converted to OkIDError
}

// All errors can be normalized
catch {
    let okidError = OkIDErrorHandler.shared.normalize(error)
    // Now you have full OkIDError benefits
}
```

For complete error handling documentation, see **[ERROR_HANDLING_GUIDE.md](Documentation/ERROR_HANDLING_GUIDE.md)**.

## Documentation

- **[README.md](README.md)**: This file - main SDK documentation
- **[QUICKSTART.md](Documentation/QUICKSTART.md)**: Quick start integration guide
- **[IMPLEMENTATION_SUMMARY.md](Documentation/IMPLEMENTATION_SUMMARY.md)**: Detailed implementation summary
- **[ERROR_HANDLING_GUIDE.md](Documentation/ERROR_HANDLING_GUIDE.md)**: Comprehensive error handling guide
- **[BIOMETRIC_QUALITY_GUIDE.md](Documentation/BIOMETRIC_QUALITY_GUIDE.md)**: Age/gender estimation and document quality guide
- **[NFC_GUIDE.md](Documentation/NFC_GUIDE.md)**: Complete NFC passport reading guide
- **[Example.swift](Example.swift)**: Usage examples for all features

## Advanced Features

### NFC Passport Reading

Complete ePassport chip reading with MRZ OCR and biometric extraction:

```swift
// Scan MRZ automatically using camera + OCR
let mrzScanner = MRZScanner()
mrzScanner.startScanning { credentials in
    // Auto-extracted from passport's Machine Readable Zone
    print("Document: \(credentials.documentNumber)")
    print("DOB: \(credentials.dateOfBirth)")
    print("Expiry: \(credentials.dateOfExpiry)")
}

// Read NFC chip data
let nfcReader = NFCPassportReader()
nfcReader.readPassport(credentials: credentials) { result in
    switch result {
    case .success(let passportData):
        print("Name: \(passportData.personalInfo?.fullName ?? "N/A")")
        print("Nationality: \(passportData.personalInfo?.nationality ?? "N/A")")
        
        if let photo = passportData.photo,
           let image = UIImage(data: photo) {
            // Display passport photo
            photoImageView.image = image
        }
        
    case .failure(let error):
        print("NFC reading failed: \(error)")
    }
}
```

**Features:**
- **MRZ OCR**: Automatic credential extraction with error correction
- **PACE/BAC**: Secure chip authentication (supports CAN)
- **DG2 Parsing**: Facial biometric extraction
- **JPEG2000 Decoding**: Photo format conversion
- **Progress Tracking**: Real-time reading progress
- **Error Handling**: Comprehensive error recovery

See **[NFC_GUIDE.md](NFC_GUIDE.md)** for complete documentation.

### Age/Gender Estimation

The SDK includes biometric estimation for liveness verification:

```swift
let estimator = AgeGenderEstimator.shared
try await estimator.initialize()

let result = try await estimator.estimate(faceImage: selfieImage)
print("Estimated age: \\(result.age)")
print("Gender: \\(result.gender) (\\(result.genderConfidence * 100)%)")
```

### Document Quality Validation

Automatic document quality checks:

```swift
let processor = DocumentProcessor.shared
await processor.initialize()

let quality = try await processor.processDocument(image: documentImage)

if quality.isGoodQuality {
    print("Document quality: Excellent")
} else {
    print("Issues: \\(quality.qualityDescription)")
}

// Individual checks
print("Blur score: \\(quality.blurScore)")
print("Is centered: \\(quality.isCentered)")
print("Has good size: \\(quality.hasGoodSize)")
print("Has glare: \\(quality.hasGlare)")
```

### Document Boundary Detection

Detect document edges using Vision framework:

```swift
let boundaries = try await processor.detectDocumentBoundaries(image: documentImage)

if let boundaries = boundaries {
    print("Top-left: (\\(boundaries.topLeft.x), \\(boundaries.topLeft.y))")
    print("Document area: \\(boundaries.area)")
    print("Center: (\\(boundaries.center.x), \\(boundaries.center.y))")
    print("Confidence: \\(boundaries.confidence)")
}
```

## Testing

```bash
swift test
```

## Example App

See the `Example/` directory for a complete sample application demonstrating all SDK features.

## License

Copyright © 2024 OkID. All rights reserved.

## Support

For technical support, please contact:
- Email: support@okid.com
- Documentation: https://docs.okid.com
- GitHub Issues: https://github.com/okid/okid-verification-sdk-ios/issues

