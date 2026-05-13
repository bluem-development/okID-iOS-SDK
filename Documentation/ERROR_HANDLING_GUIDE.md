# Error Handling Guide

## Overview

The OkID Verification SDK implements a comprehensive error handling system that provides:

- **Centralized Error Types**: All errors are represented by the `OkIDError` enum
- **User-Friendly Messages**: Each error includes clear descriptions and recovery suggestions
- **Error Categories**: Errors are organized by category for better tracking and handling
- **Recovery Strategies**: Errors indicate whether they're recoverable and what action is needed
- **Automatic Conversion**: Legacy error types are automatically converted to `OkIDError`

## Error Types

### OkIDError

The main error type that covers all error scenarios in the SDK:

```swift
enum OkIDError {
    // Network Errors
    case networkUnavailable
    case requestTimeout
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case rateLimitExceeded(retryAfter: TimeInterval?)
    
    // Authentication Errors
    case unauthorized
    case invalidCredentials
    case sessionExpired
    case invalidAPIKey
    
    // Validation Errors
    case verificationNotFound
    case verificationExpired
    case verificationAlreadyCompleted
    case invalidVerificationState(expected: String, actual: String)
    case moduleNotAvailable(module: String)
    
    // Document Errors
    case documentUploadFailed(reason: String)
    case invalidDocumentFormat
    case documentTooLarge(maxSize: Int)
    case documentBlurry(score: Double, threshold: Double)
    case documentNotDetected
    case invalidDocumentSide
    case glareDetected
    case documentExpired
    
    // Liveness Errors
    case faceNotDetected
    case multipleFacesDetected
    case faceTooClose
    case faceTooFar
    case faceNotCentered
    case poorLighting
    case livenessCheckFailed(reason: String)
    
    // NFC Errors
    case nfcNotSupported
    case nfcNotEnabled
    case nfcTagConnectionLost
    case nfcAuthenticationFailed
    case nfcInvalidCredentials
    case nfcDataGroupNotFound(group: String)
    case nfcInvalidMRZ
    case nfcUnsupportedDocument
    case nfcTimeout
    case nfcUserCancelled
    
    // QR Code Errors
    case qrCodeInvalidURL
    case qrCodeUnsupportedOrigin
    case qrCodeMissingData
    case qrCodeInvalidFormat
    
    // Camera Errors
    case cameraPermissionDenied
    case cameraNotAvailable
    case cameraInitializationFailed
    
    // Storage Errors
    case storageWriteFailed
    case storageReadFailed
    case storageQuotaExceeded
    case dataCorrupted
    
    // Form Errors
    case invalidFormData(field: String, reason: String)
    case requiredFieldMissing(field: String)
    case invalidFieldFormat(field: String, expected: String)
    
    // Processing Errors
    case imageProcessingFailed(reason: String)
    case faceDetectionFailed(reason: String)
    case biometricProcessingFailed(reason: String)
    case modelLoadFailed(model: String)
    
    // Configuration Errors
    case invalidConfiguration(reason: String)
    case missingAPIKey
    case invalidBaseURL
    
    // Generic Errors
    case cancelled
    case unknown(Error)
}
```

## Error Properties

### errorDescription
User-friendly error message suitable for display:

```swift
let error = OkIDError.networkUnavailable
print(error.errorDescription)
// "No internet connection. Please check your network settings and try again."
```

### recoverySuggestion
Suggested action for recovery:

```swift
let error = OkIDError.documentBlurry(score: 50, threshold: 100)
print(error.recoverySuggestion)
// "Take a new photo ensuring good lighting and focus."
```

### category
Error category for analytics and logging:

```swift
let error = OkIDError.faceNotDetected
print(error.category) // .liveness
```

### isRecoverable
Whether the error can be recovered from by retrying:

```swift
let error = OkIDError.networkUnavailable
if error.isRecoverable {
    // Show retry button
}
```

### requiresUserAction
Whether explicit user action is needed:

```swift
let error = OkIDError.cameraPermissionDenied
if error.requiresUserAction {
    // Guide user to Settings
}
```

## Using Error Handler

### Basic Error Handling

```swift
do {
    try await apiClient.uploadDocument(...)
} catch {
    OkIDErrorHandler.shared.handle(
        error,
        context: "Document upload"
    )
}
```

### Presenting Errors to Users

```swift
do {
    try await apiClient.validateVerification(...)
} catch {
    await OkIDErrorHandler.shared.presentError(
        error,
        from: self,
        onRetry: {
            // Retry the operation
            Task {
                await self.validateAgain()
            }
        },
        onDismiss: {
            // Handle dismissal
            self.navigationController?.popViewController(animated: true)
        }
    )
}
```

### Error Normalization

Convert any error to `OkIDError`:

```swift
let error: Error = // some error
let okidError = OkIDErrorHandler.shared.normalize(error)

// Now you can access all OkIDError properties
print(okidError.category)
print(okidError.isRecoverable)
```

### Error Listeners

Listen for errors globally:

```swift
OkIDErrorHandler.shared.addErrorListener { error in
    // Send to analytics
    Analytics.logError(
        category: error.category.rawValue,
        message: error.errorDescription ?? "Unknown"
    )
}
```

## Best Practices

### 1. Always Provide Context

```swift
// Bad
OkIDErrorHandler.shared.handle(error)

// Good
OkIDErrorHandler.shared.handle(
    error,
    context: "NFCReadingViewController.startReading"
)
```

### 2. Use Appropriate Severity

```swift
// For debugging/development issues
OkIDErrorHandler.shared.handle(
    error,
    context: "Image preprocessing",
    severity: .debug
)

// For user-facing errors
OkIDErrorHandler.shared.handle(
    error,
    context: "Document upload",
    severity: .error
)

// For critical system errors
OkIDErrorHandler.shared.handle(
    error,
    context: "Camera initialization",
    severity: .critical
)
```

### 3. Implement Retry Logic for Recoverable Errors

```swift
func uploadDocument() async {
    do {
        try await apiClient.uploadDocument(...)
    } catch {
        let okidError = OkIDErrorHandler.shared.normalize(error)
        
        if okidError.isRecoverable {
            await OkIDErrorHandler.shared.presentError(
                error,
                from: self,
                onRetry: {
                    Task {
                        await self.uploadDocument() // Retry
                    }
                }
            )
        } else {
            // Show error without retry
            await OkIDErrorHandler.shared.presentError(
                error,
                from: self,
                onDismiss: {
                    self.handleUnrecoverableError()
                }
            )
        }
    }
}
```

### 4. Handle User Action Required Errors

```swift
func checkPermissions() async throws {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    if status == .denied {
        throw OkIDError.cameraPermissionDenied
    }
}

// Usage
do {
    try await checkPermissions()
} catch {
    let okidError = OkIDErrorHandler.shared.normalize(error)
    
    if okidError.requiresUserAction {
        // Show guidance to open Settings
        await OkIDErrorHandler.shared.presentError(
            error,
            from: self,
            onDismiss: {
                // Optionally open Settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
            }
        )
    }
}
```

### 5. Use Task.catching for Async Operations

```swift
Task.catching(context: "Profile loading") {
    return try await storage.loadProfile()
} onError: { error in
    // Handle error
    print("Failed to load profile: \(error.errorDescription)")
}
```

### 6. Use Result.handle for Result Types

```swift
let result: Result<Data, Error> = // ...

result.handle(
    context: "Image decoding",
    onSuccess: { data in
        // Process data
    },
    onFailure: { error in
        // Handle specific error
        if case .dataCorrupted = error {
            // Clear corrupted data
        }
    }
)
```

## Error Recovery Strategies

### Network Errors
- **Auto-retry** with exponential backoff
- **Rate limiting** respect retry-after headers
- **Offline mode** queue requests for later

### Document Errors
- **Blur detection** prompt user to retake photo
- **Glare detection** guide user to adjust lighting
- **Document detection** show alignment guides

### Liveness Errors
- **Face positioning** provide real-time feedback
- **Lighting issues** guide to better lit area
- **Multiple attempts** allow retries with guidance

### NFC Errors
- **Connection lost** prompt to hold steady
- **Invalid credentials** verify input fields
- **Timeout** increase timeout for slow readers

### Camera Errors
- **Permission denied** guide to Settings
- **Not available** suggest closing other apps
- **Initialization failed** retry after delay

### Storage Errors
- **Quota exceeded** prompt to clear space
- **Write failed** retry with smaller data
- **Read failed** fallback to defaults

## Migration from Legacy Errors

Legacy error types are automatically converted:

```swift
// Old code using OkIDAPIError
catch let error as OkIDAPIError {
    // ...
}

// New code - automatic conversion
catch {
    let okidError = OkIDErrorHandler.shared.normalize(error)
    // error is now OkIDError with all benefits
}
```

## Error Logging

Errors are automatically logged with:
- **Category** for filtering
- **Context** for debugging
- **Severity** for prioritization
- **Recovery suggestion** for fixing

Example log output:
```
❌ NETWORK [Document upload]: Request timed out. Please check your connection and try again.
💡 Recovery suggestion: Check your internet connection or try again later.
```

## Testing Error Handling

```swift
func testErrorHandling() async {
    let error = OkIDError.documentBlurry(score: 50, threshold: 100)
    
    // Test error properties
    XCTAssertEqual(error.category, .document)
    XCTAssertTrue(error.isRecoverable)
    XCTAssertFalse(error.requiresUserAction)
    XCTAssertNotNil(error.errorDescription)
    XCTAssertNotNil(error.recoverySuggestion)
}
```

## Summary

The OkID SDK's error handling system provides:

1. ✅ **Comprehensive** - Covers all error scenarios
2. ✅ **User-Friendly** - Clear messages and recovery suggestions
3. ✅ **Developer-Friendly** - Easy to use and integrate
4. ✅ **Debuggable** - Detailed logging and context
5. ✅ **Recoverable** - Built-in retry and recovery strategies
6. ✅ **Extensible** - Easy to add new error types
7. ✅ **Type-Safe** - Compile-time error checking

Always use `OkIDErrorHandler` for consistent error handling across your implementation.
