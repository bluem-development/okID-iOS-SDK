# NFC Passport Reading - iOS SDK Implementation Guide

Complete guide for NFC passport reading functionality in the OkID iOS SDK.

## Table of Contents

1. [Overview](#overview)
2. [Core Components](#core-components)
3. [MRZ Scanning](#mrz-scanning)
4. [NFC Reading](#nfc-reading)
5. [Data Models](#data-models)
6. [Integration Examples](#integration-examples)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The NFC module enables reading biometric data from ePassports (MRTD - Machine Readable Travel Documents) using:
- **MRZ OCR**: Automatic extraction of document number, DOB, and expiry dates from passport's Machine Readable Zone
- **NFC Reading**: Secure reading of passport chip data using PACE (Password Authenticated Connection Establishment) or BAC (Basic Access Control)
- **DG2 Parsing**: Extraction of facial biometric data (photo) from Data Group 2

###NFC Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NFC Module                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐ │
│  │ MRZ Scanner  │────▶│  NFC Input   │────▶│ NFC Reading  │ │
│  │  (OCR)       │     │  (Manual)    │     │  (CoreNFC)   │ │
│  └──────────────┘     └──────────────┘     └──────────────┘ │
│         │                     │                     │         │
│         └────────────────┬────┴─────────────────────┘         │
│                          ▼                                     │
│                 ┌──────────────┐                              │
│                 │  NFC Result  │                              │
│                 │  (Display)   │                              │
│                 └──────────────┘                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. MRZ Parser (`MRZParser.swift`)

Extracts and validates passport data from MRZ (Machine Readable Zone).

**Features:**
- TD3 format parsing (2-line passport MRZ)
- Check digit validation (7-3-1 weighted algorithm)
- OCR error correction (common substitutions: O↔0, I↔1, etc.)
- Field extraction: document number, DOB, expiry date
- Cross-frame confidence tracking

**Key Methods:**

```swift
// Parse MRZ line 2 (contains data)
let parsed = MRZParser.parseLine2(mrzText)
let docNumber = parsed["documentNumber"]
let dob = parsed["dateOfBirth"]  // YYMMDD format
let expiry = parsed["dateOfExpiry"]  // YYMMDD format

// Validate MRZ line 1 (passport format check)
if MRZParser.isPassportMRZLine1(line1) {
    // Valid passport MRZ detected
}

// Validate MRZ line 2 pattern
if MRZParser.looksLikeMRZLine2(line2) {
    // Potential data line detected
}

// OCR error correction
let corrected = MRZParser.correctOCRErrors(rawOCRText)
```

**MRZ Format (TD3):**

```
Line 1: P<NLDTEST<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        │││   │
        ││└───┴── Names (separated by <<)
        │└────── Country code (3 letters)
        └─────── Document type (P = Passport)

Line 2: AB1234567<NLD7801015M2512315<<<<<<<<<<<<<<<8
        │        │   │      │ │      │               │
        │        │   │      │ │      │               └─ Composite check digit
        │        │   │      │ │      └───────────────── Optional data
        │        │   │      │ └──────────────────────── Expiry date (YYMMDD) + check
        │        │   │      └─────────────────────────── Gender (M/F/<)
        │        │   └────────────────────────────────── DOB (YYMMDD) + check
        │        └────────────────────────────────────── Nationality
        └─────────────────────────────────────────────── Document number + check
```

### 2. MRZ Tracker (`MRZTracker.swift`)

Tracks MRZ field detection across multiple camera frames for confidence.

**Features:**
- Multi-frame validation (requires 3+ consistent matches)
- Separate tracking for each field (doc number, DOB, expiry)
- Real-time status indicators (missing/pending/validated)
- History management (last 5 frames)

**Usage:**

```swift
let tracker = MRZTracker()

// Add detection from each camera frame
tracker.addDetection(
    documentNumber: "AB1234567",
    dateOfBirth: "780101",
    dateOfExpiry: "251231"
)

// Check field status
switch tracker.documentNumberStatus {
case .missing:
    print("Not yet detected")
case .pending:
    print("Detected, waiting for confirmation...")
case .validated:
    print("✓ Confirmed!")
}

// Get validated values (only when confident)
if tracker.allFieldsValidated {
    let docNumber = tracker.validatedDocumentNumber
    let dob = tracker.validatedDateOfBirth
    let expiry = tracker.validatedDateOfExpiry
}
```

### 3. DG2 Parser (`DG2Parser.swift`)

Extracts facial biometric data from ePassport Data Group 2.

**Features:**
- ISO/IEC 19794-5 format parsing
- TLV (Tag-Length-Value) structure parsing
- Biometric data extraction
- Face image data isolation

**Usage:**

```swift
let parser = DG2Parser(data: dg2Data)
if let imageData = parser.extractImageData() {
    // imageData contains the raw face image (JPEG or JPEG2000)
    let image = ImageDecoderService.shared.decodeJPEG2000(imageData)
}
```

**DG2 Structure:**

```
DG2 (Data Group 2)
├── 0x75 - Outer wrapper
├── 0x7F61 - Biometric Information Template
│   ├── 0x02 - Number of instances
│   └── 0x7F60 - Biometric Information Group
│       ├── 0xA1 - Biometric Header (skip)
│       └── 0x5F2E/0x7F2E - Biometric data block
│           └── ISO 19794-5 format
│               ├── Format ID (4 bytes)
│               ├── Version (4 bytes)
│               ├── Record length (4 bytes)
│               ├── Face image metadata
│               └── Image data (JPEG/JPEG2000)
```

### 4. Image Decoder (`ImageDecoderService.swift`)

Decodes JPEG2000 and other image formats from passport chips.

**Features:**
- JPEG2000 decoding (via ImageIO)
- JPEG detection and decoding
- Format auto-detection
- Fallback handling

**Usage:**

```swift
let decoder = ImageDecoderService.shared

// Decode JPEG2000
if let image = decoder.decodeJPEG2000(jp2Data) {
    photoImageView.image = image
}

// Check format
if decoder.isJPEG2000(imageData) {
    print("JPEG2000 format detected")
}

// Convert to JPEG
if let jpegData = decoder.convertToJPEG(imageData, quality: 0.9) {
    // Upload jpegData
}
```

---

## MRZ Scanning

### OCR-based MRZ Detection

The SDK uses Vision framework's text recognition to scan MRZ from camera feed.

**Implementation Approach:**

```swift
import Vision
import AVFoundation

class MRZScannerViewController: UIViewController {
    let tracker = MRZTracker()
    let textRecognizer = VNRecognizeTextRequest()
    
    func processCameraFrame(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        try? handler.perform([textRecognizer])
        
        guard let results = textRecognizer.results else { return }
        
        // Extract all text lines
        let lines = results.compactMap { $0.topCandidates(1).first?.string }
        
        // Look for MRZ pattern (line 1 + line 2)
        for i in 0..<lines.count - 1 {
            let line1 = lines[i]
            let line2 = lines[i + 1]
            
            if MRZParser.isPassportMRZLine1(line1) &&
               MRZParser.looksLikeMRZLine2(line2) {
                
                let parsed = MRZParser.parseLine2(line2)
                
                tracker.addDetection(
                    documentNumber: parsed["documentNumber"],
                    dateOfBirth: parsed["dateOfBirth"],
                    dateOfExpiry: parsed["dateOfExpiry"]
                )
                
                if tracker.allFieldsValidated {
                    onMRZDetected(tracker)
                }
                
                break
            }
        }
    }
}
```

**Best Practices:**
- Process frames at 5 FPS (200ms intervals) to balance performance
- Use high resolution preset for better OCR accuracy
- Show real-time field status indicators (✓/⏳/○)
- Provide visual guide for MRZ area alignment
- Auto-proceed when all fields validated

---

## NFC Reading

### Authentication Methods

#### 1. BAC (Basic Access Control)
Uses MRZ data (document number + DOB + expiry) to generate access key.

```swift
let credentials = OkIDPassportCredentials(
    documentNumber: "AB1234567",
    dateOfBirth: Date(timeIntervalSince1970: 252460800),  // 1978-01-01
    dateOfExpiry: Date(timeIntervalSince1970: 1798761600)  // 2027-01-01
)

// SDK uses BAC if no CAN provided
```

#### 2. PACE with CAN (Recommended for newer passports)
Uses 6-digit Card Access Number (printed on passport front).

```swift
let credentials = OkIDPassportCredentials(
    documentNumber: "AB1234567",
    dateOfBirth: Date(timeIntervalSince1970: 252460800),
    dateOfExpiry: Date(timeIntervalSince1970: 1798761600),
    can: "123456"  // 6-digit CAN
)

// SDK automatically uses PACE if CAN provided
```

### NFC Reading Flow

```
1. Initialize NFC Session
   └─▶ Poll for ISO 14443 tag

2. Read EF.CardAccess (if available)
   └─▶ Determine PACE support

3. Establish Secure Session
   ├─▶ PACE (if CAN or CardAccess available)
   └─▶ BAC (fallback)

4. Read EF.COM
   └─▶ Get list of available Data Groups

5. Read Data Groups
   ├─▶ DG1: MRZ (personal info)
   ├─▶ DG2: Face image
   ├─▶ DG11: Additional personal details
   ├─▶ DG12: Additional document details
   ├─▶ DG15: Active Auth public key
   └─▶ EF.SOD: Document security

6. Extract and Parse
   ├─▶ Parse MRZ from DG1
   ├─▶ Extract photo from DG2
   └─▶ Validate with SOD

7. Return Results
   └─▶ OkIDPassportData
```

### Progress Tracking

```swift
struct NFCReadingProgress {
    let state: NFCReadingState  // idle, detecting, connecting, etc.
    let message: String  // User-friendly message
    let progress: Double  // 0.0 to 1.0
}

// States:
// .detecting          → "Hold passport near device..." (0%)
// .connecting         → "Connecting to passport..." (10%)
// .readingCardAccess  → "Reading card access..." (20%)
// .establishingSession→ "Establishing session..." (30%)
// .readingCOM         → "Reading COM..." (40%)
// .readingDataGroups  → "Reading DG1..." (50-99%)
// .completed          → "Reading complete!" (100%)
// .error              → Error message
```

---

## Data Models

### PassportCredentials

```swift
public struct OkIDPassportCredentials {
    let documentNumber: String  // e.g., "AB1234567"
    let dateOfBirth: Date
    let dateOfExpiry: Date
    let can: String?  // Optional 6-digit CAN
    
    var hasCAN: Bool  // true if CAN is 6 digits
    var dobFormatted: String  // YYMMDD format
    var expiryFormatted: String  // YYMMDD format
    
    func validate() -> Bool
}
```

### PersonalInfo (from DG1)

```swift
public struct OkIDPersonalInfo {
    let documentType: String?  // "P" for passport
    let issuingState: String?  // 3-letter country code
    let documentNumber: String?
    let lastName: String?
    let firstName: String?
    let nationality: String?
    let dateOfBirth: Date?
    let gender: String?  // "M", "F", or "<"
    let dateOfExpiry: Date?
    let optionalData1: String?
    let optionalData2: String?
    
    var fullName: String  // "FirstName LastName"
}
```

### PassportData (Complete Result)

```swift
public struct OkIDPassportData {
    let personalInfo: OkIDPersonalInfo?
    let photo: Data?  // JPEG image data
    let dataGroupsRead: [String]  // ["DG1", "DG2", "DG11", ...]
    let readAt: Date
    let additionalInfo: [String: Any]?  // Extra metadata
}
```

---

## Integration Examples

### Example 1: Full NFC Flow

```swift
import OkIDVerificationSDK

class PassportScanViewController: UIViewController {
    
    func startNFCScan() {
        // Option 1: Manual entry
        let credentials = OkIDPassportCredentials(
            documentNumber: "AB1234567",
            dateOfBirth: parseDate("01.01.1978"),
            dateOfExpiry: parseDate("01.01.2027"),
            can: "123456"  // Optional
        )
        
        readPassport(credentials: credentials)
        
        // Option 2: From MRZ scan
        showMRZScanner { scannedCredentials in
            self.readPassport(credentials: scannedCredentials)
        }
    }
    
    func readPassport(credentials: OkIDPassportCredentials) {
        guard NFCReader.isAvailable else {
            showAlert("NFC not available on this device")
            return
        }
        
        let reader = NFCPassportReader()
        
        reader.readPassport(
            credentials: credentials,
            progress: { progress in
                self.updateProgress(progress)
            },
            completion: { result in
                switch result {
                case .success(let passportData):
                    self.handleSuccess(passportData)
                case .failure(let error):
                    self.handleError(error)
                }
            }
        )
    }
    
    func handleSuccess(_ data: OkIDPassportData) {
        print("Name: \(data.personalInfo?.fullName ?? "N/A")")
        print("Nationality: \(data.personalInfo?.nationality ?? "N/A")")
        print("Data groups: \(data.dataGroupsRead.joined(separator: ", "))")
        
        if let photoData = data.photo,
           let image = UIImage(data: photoData) {
            photoImageView.image = image
        }
    }
}
```

### Example 2: MRZ Scanner Integration

```swift
class MRZScannerController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let tracker = MRZTracker()
    var captureSession: AVCaptureSession?
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        captureSession?.addOutput(videoOutput)
        
        captureSession?.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            self.processLines(lines)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func processLines(_ lines: [String]) {
        for i in 0..<lines.count - 1 {
            if MRZParser.isPassportMRZLine1(lines[i]) &&
               MRZParser.looksLikeMRZLine2(lines[i + 1]) {
                
                let parsed = MRZParser.parseLine2(lines[i + 1])
                
                tracker.addDetection(
                    documentNumber: parsed["documentNumber"],
                    dateOfBirth: parsed["dateOfBirth"],
                    dateOfExpiry: parsed["dateOfExpiry"]
                )
                
                updateUI()
                
                if tracker.allFieldsValidated {
                    onMRZComplete()
                }
            }
        }
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. NFC Not Available

**Problem**: NFC reading fails immediately

**Solutions**:
- Check device support (iPhone 7+ required)
- Verify NFC is enabled in Settings
- Request NFC permissions in Info.plist
- Check for iOS version compatibility (iOS 13+)

```swift
import CoreNFC

if NFCReaderSession.readingAvailable {
    // NFC is available
} else {
    showAlert("NFC not supported on this device")
}
```

#### 2. Authentication Failed

**Problem**: "Authentication failed" error during NFC reading

**Solutions**:
- Verify document number (no spaces/dashes)
- Check date formats (DDMMYY)
- Ensure dates match passport exactly
- Try CAN-based PACE if available
- Check passport is NFC-enabled (chip symbol)

```swift
// Correct format
let credentials = OkIDPassportCredentials(
    documentNumber: "AB1234567",  // No spaces
    dateOfBirth: Date(...),  // Exact date
    dateOfExpiry: Date(...),
    can: "123456"  // Try with CAN
)
```

#### 3. MRZ Detection Fails

**Problem**: Camera can't detect MRZ text

**Solutions**:
- Improve lighting conditions
- Hold camera steady over MRZ area
- Use high resolution camera preset
- Ensure MRZ area is clean/unobstructed
- Check OCR language settings (Latin script)

```swift
// Optimize OCR
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en"]
request.usesLanguageCorrection = true
```

#### 4. DG2 Image Extraction Fails

**Problem**: Can't extract photo from passport

**Solutions**:
- Check Data Group 2 is available in EF.COM
- Verify DG2 was read successfully
- Handle both JPEG and JPEG2000 formats
- Check for DG2 parsing errors

```swift
if let imageData = dg2Parser.extractImageData() {
    // Check format
    if ImageDecoderService.shared.isJPEG2000(imageData) {
        // Decode JPEG2000
        image = ImageDecoderService.shared.decodeJPEG2000(imageData)
    } else {
        // Already JPEG
        image = UIImage(data: imageData)
    }
}
```

#### 5. Connection Lost During Reading

**Problem**: "Tag connection lost" error

**Solutions**:
- Hold passport steady against device
- Ensure NFC antenna position (usually top back of iPhone)
- Remove phone case if metallic
- Don't move passport during reading
- Avoid electromagnetic interference

---

## iOS Requirements

### Info.plist Configuration

```xml
<key>NFCReaderUsageDescription</key>
<string>NFC access is required to read your passport chip data for identity verification.</string>

<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
</array>
```

### Capabilities

1. Enable "Near Field Communication Tag Reading" in Xcode capabilities
2. Add NFC entitlement to App ID in Apple Developer Portal

### Minimum Requirements

- **Device**: iPhone 7 or newer
- **iOS**: 13.0+
- **Xcode**: 12.0+
- **Swift**: 5.3+

---

## Best Practices

### Security

1. **Never log sensitive data**:
   ```swift
   // ❌ Bad
   print("Document number: \(credentials.documentNumber)")
   
   // ✓ Good
   print("Reading passport data...")
   ```

2. **Validate all inputs**:
   ```swift
   guard credentials.validate() else {
       throw ValidationError.invalidCredentials
   }
   ```

3. **Use secure storage for credentials**:
   ```swift
   // Store in Keychain, not UserDefaults
   KeychainService.save(credentials, for: "passport_creds")
   ```

### Performance

1. **Throttle camera frame processing** (5 FPS max)
2. **Use background threads for OCR**
3. **Cache MRZ tracker results**
4. **Preload Vision models**

### UX

1. **Show clear instructions** (where to place passport)
2. **Provide real-time feedback** (field status indicators)
3. **Display progress during NFC reading** (percentage + message)
4. **Handle errors gracefully** (retry options)
5. **Vibrate/sound on success**

---

## Summary

The OkID iOS SDK provides a complete NFC passport reading solution with:

✅ **MRZ OCR Scanning**: Automatic credential extraction with error correction  
✅ **NFC Reading**: PACE and BAC support for secure chip reading  
✅ **Biometric Extraction**: DG2 parsing with JPEG/JPEG2000 decoding  
✅ **Cross-frame Validation**: Confidence-based field tracking  
✅ **Progress Tracking**: Real-time user feedback  
✅ **Error Handling**: Comprehensive error types and recovery  

For implementation support: support@okid.com  
Documentation: https://docs.okid.com/nfc

