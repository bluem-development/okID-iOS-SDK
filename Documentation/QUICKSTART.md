# OkID iOS SDK - Quick Start Guide

## Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "path/to/OkIDVerificationSDK", from: "1.0.0")
]
```

Or in Xcode: **File → Add Packages → Enter path**

## Basic Setup (3 Steps)

### 1. Import & Configure
```swift
import OkIDVerificationSDK

let config = OkIDSDKConfig(
    baseUrl: "https://api.okid.com"
)
```

### 2. Add Permissions to Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>Required for document and selfie capture</string>

<key>NFCReaderUsageDescription</key>
<string>Required to read passport chip</string>
```

### 3. Start Verification
```swift
await OkIDVerificationSDK.shared.startVerification(
    verificationId: "ver_xxx",
    config: config,
    from: viewController
)
```

## Common Use Cases

### Get Result
```swift
let result = await OkIDVerificationSDK.shared.startVerificationForResult(
    verificationId: "ver_xxx",
    config: config,
    from: viewController
)

if result?.isSuccess == true {
    // Success!
}
```

### QR Code Flow
```swift
let result = await OkIDVerificationSDK.shared.startFromQRCode(
    from: viewController,
    config: config
)
```

### Profile Management
```swift
// Check status
let status = await OkIDVerificationSDK.shared.getProfileStatus()

// Manage
await OkIDVerificationSDK.shared.manageProfile(from: vc, config: config)

// Delete
await OkIDVerificationSDK.shared.deleteProfile()
```

## Custom Theme
```swift
let theme = OkIDThemeConfig(
    colors: OkIDColorPalette(
        primary: .systemBlue,
        secondary: .systemGray,
        accent: .systemGreen,
        warning: .systemOrange,
        error: .systemRed,
        background: .white,
        surface: .systemGray6,
        text: .black,
        textSecondary: .systemGray,
        border: .systemGray4
    ),
    typography: .defaultConfig,
    spacing: .defaultConfig,
    branding: OkIDBrandingConfig(
        organizationName: "Your Company",
        logoImage: UIImage(named: "logo"),
        primaryColor: .systemBlue,
        secondaryColor: .systemGray
    ),
    borderRadius: .defaultConfig
)

let config = OkIDSDKConfig(baseUrl: "...", theme: theme)
```

## Error Handling
```swift
do {
    let apiClient = VerificationAPIClient(config: config)
    let response = try await apiClient.uploadDocument(...)
} catch let error as OkIDAPIError {
    print("API Error: \\(error.localizedDescription)")
}
```

## File Structure Reference

```
OkIDVerificationSDK/
├── Sources/
│   ├── Core/                    # Main SDK + Config
│   ├── Models/                  # Data models (Codable)
│   ├── Services/                # API, Storage, Detection
│   ├── Modules/                 # UI modules (7 modules)
│   └── Utils/                   # Helpers, Extensions
├── Package.swift                # SPM manifest
├── README.md                    # Full documentation
├── Example.swift                # Code examples
└── IMPLEMENTATION_SUMMARY.md   # Technical details
```

## 23 Swift Files Created

**Core (2)**: SDK entry point + Configuration  
**Models (6)**: All data structures  
**Services (6)**: API, Storage, Face/NFC detection  
**Modules (7)**: Terms, Document, Liveness, FormData, Validation, QR, Profile  
**Utils (3)**: QR parser, Blur detection, Extensions  

## Zero Dependencies

Built entirely with native iOS frameworks:
- Foundation, UIKit, AVFoundation
- Vision, CoreNFC, Security

## Key Features

✅ Async/await throughout  
✅ Document + Selfie capture  
✅ NFC passport reading  
✅ QR code scanning  
✅ Secure profile storage (Keychain)  
✅ Face detection (Vision)  
✅ Image quality (blur detection)  
✅ Custom theming  
✅ Desktop sync (SSE)  
✅ Full error handling  

## Requirements

- iOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## Next Steps

1. See **README.md** for complete documentation
2. Check **Example.swift** for usage patterns
3. Read **IMPLEMENTATION_SUMMARY.md** for architecture

---

**Pure native iOS SDK with async/await**  
Translated from the reference implementation with full feature parity  
Location: `/Users/karen/Documents/tests_sdk/OkIDVerificationSDK/`

