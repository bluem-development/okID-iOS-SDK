import Foundation

// MARK: - OkID Error

/// Comprehensive error type for OkID SDK
public enum OkIDError: Error, LocalizedError, Equatable {
    
    // MARK: - Network Errors
    
    case networkUnavailable
    case requestTimeout
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case rateLimitExceeded(retryAfter: TimeInterval?)
    
    // MARK: - Authentication Errors
    
    case unauthorized
    case invalidCredentials
    case sessionExpired
    case invalidAPIKey
    
    // MARK: - Validation Errors
    
    case verificationNotFound
    case verificationExpired
    case verificationAlreadyCompleted
    case invalidVerificationState(expected: String, actual: String)
    case moduleNotAvailable(module: String)
    
    // MARK: - Document Errors
    
    case documentUploadFailed(reason: String)
    case invalidDocumentFormat
    case documentTooLarge(maxSize: Int)
    case documentBlurry(score: Double, threshold: Double)
    case documentNotDetected
    case invalidDocumentSide
    case glareDetected
    case documentExpired
    
    // MARK: - Liveness Errors
    
    case faceNotDetected
    case multipleFacesDetected
    case faceTooClose
    case faceTooFar
    case faceNotCentered
    case poorLighting
    case livenessCheckFailed(reason: String)
    
    // MARK: - NFC Errors
    
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
    
    // MARK: - QR Code Errors
    
    case qrCodeInvalidURL
    case qrCodeUnsupportedOrigin
    case qrCodeMissingData
    case qrCodeInvalidFormat
    
    // MARK: - Camera Errors
    
    case cameraPermissionDenied
    case cameraNotAvailable
    case cameraInitializationFailed
    
    // MARK: - Storage Errors
    
    case storageWriteFailed
    case storageReadFailed
    case storageQuotaExceeded
    case dataCorrupted
    
    // MARK: - Form Errors
    
    case invalidFormData(field: String, reason: String)
    case requiredFieldMissing(field: String)
    case invalidFieldFormat(field: String, expected: String)
    
    // MARK: - Processing Errors
    
    case imageProcessingFailed(reason: String)
    case faceDetectionFailed(reason: String)
    case biometricProcessingFailed(reason: String)
    case modelLoadFailed(model: String)
    
    // MARK: - Configuration Errors
    
    case invalidConfiguration(reason: String)
    case missingAPIKey
    case invalidBaseURL
    
    // MARK: - Generic Errors
    
    case cancelled
    case unknown(Error)
    
    // MARK: - Error Description
    
    public var errorDescription: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "No internet connection. Please check your network settings and try again."
        case .requestTimeout:
            return "Request timed out. Please check your connection and try again."
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (\(code)): \(message)"
            }
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Too many requests. Please wait \(Int(retryAfter)) seconds before trying again."
            }
            return "Too many requests. Please try again later."
            
        // Authentication Errors
        case .unauthorized:
            return "Unauthorized access. Please check your credentials."
        case .invalidCredentials:
            return "Invalid credentials. Please verify your information."
        case .sessionExpired:
            return "Your session has expired. Please start over."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
            
        // Validation Errors
        case .verificationNotFound:
            return "Verification not found. Please start a new verification."
        case .verificationExpired:
            return "Verification has expired. Please start a new verification."
        case .verificationAlreadyCompleted:
            return "This verification has already been completed."
        case .invalidVerificationState(let expected, let actual):
            return "Invalid verification state. Expected \(expected), but got \(actual)."
        case .moduleNotAvailable(let module):
            return "Module '\(module)' is not available for this verification."
            
        // Document Errors
        case .documentUploadFailed(let reason):
            return "Document upload failed: \(reason)"
        case .invalidDocumentFormat:
            return "Invalid document format. Please use a supported image format (JPEG, PNG)."
        case .documentTooLarge(let maxSize):
            return "Document image is too large. Maximum size is \(maxSize / 1024 / 1024)MB."
        case .documentBlurry(let score, let threshold):
            return "Document image is too blurry (score: \(Int(score)), required: \(Int(threshold))). Please take a clearer photo."
        case .documentNotDetected:
            return "Document not detected. Please ensure the entire document is visible and try again."
        case .invalidDocumentSide:
            return "Invalid document side. Please capture the correct side of the document."
        case .glareDetected:
            return "Glare detected on document. Please adjust lighting and try again."
        case .documentExpired:
            return "This document has expired. Please use a valid document."
            
        // Liveness Errors
        case .faceNotDetected:
            return "Face not detected. Please ensure your face is visible and well-lit."
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one person is visible."
        case .faceTooClose:
            return "Face too close. Please move back from the camera."
        case .faceTooFar:
            return "Face too far. Please move closer to the camera."
        case .faceNotCentered:
            return "Face not centered. Please center your face in the frame."
        case .poorLighting:
            return "Poor lighting conditions. Please move to a well-lit area."
        case .livenessCheckFailed(let reason):
            return "Liveness check failed: \(reason)"
            
        // NFC Errors
        case .nfcNotSupported:
            return "NFC is not supported on this device."
        case .nfcNotEnabled:
            return "NFC is disabled. Please enable NFC in Settings."
        case .nfcTagConnectionLost:
            return "Connection to passport lost. Please hold steady and try again."
        case .nfcAuthenticationFailed:
            return "Passport authentication failed. Please verify your credentials."
        case .nfcInvalidCredentials:
            return "Invalid passport credentials. Please check document number, date of birth, and expiry date."
        case .nfcDataGroupNotFound(let group):
            return "Data group '\(group)' not found on passport."
        case .nfcInvalidMRZ:
            return "Could not read MRZ data from passport."
        case .nfcUnsupportedDocument:
            return "This document type is not supported for NFC reading."
        case .nfcTimeout:
            return "NFC reading timed out. Please try again."
        case .nfcUserCancelled:
            return "NFC reading was cancelled."
            
        // QR Code Errors
        case .qrCodeInvalidURL:
            return "Invalid QR code URL."
        case .qrCodeUnsupportedOrigin:
            return "This QR code is from an unsupported origin."
        case .qrCodeMissingData:
            return "QR code is missing required data."
        case .qrCodeInvalidFormat:
            return "QR code format is not recognized."
            
        // Camera Errors
        case .cameraPermissionDenied:
            return "Camera permission denied. Please enable camera access in Settings."
        case .cameraNotAvailable:
            return "Camera not available. Please check if another app is using the camera."
        case .cameraInitializationFailed:
            return "Failed to initialize camera. Please try again."
            
        // Storage Errors
        case .storageWriteFailed:
            return "Failed to save data. Please check available storage space."
        case .storageReadFailed:
            return "Failed to read saved data."
        case .storageQuotaExceeded:
            return "Storage quota exceeded. Please free up some space."
        case .dataCorrupted:
            return "Saved data is corrupted. Please start over."
            
        // Form Errors
        case .invalidFormData(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .requiredFieldMissing(let field):
            return "Required field '\(field)' is missing."
        case .invalidFieldFormat(let field, let expected):
            return "Invalid format for '\(field)'. Expected: \(expected)"
            
        // Processing Errors
        case .imageProcessingFailed(let reason):
            return "Image processing failed: \(reason)"
        case .faceDetectionFailed(let reason):
            return "Face detection failed: \(reason)"
        case .biometricProcessingFailed(let reason):
            return "Biometric processing failed: \(reason)"
        case .modelLoadFailed(let model):
            return "Failed to load '\(model)' model. Please try again."
            
        // Configuration Errors
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .missingAPIKey:
            return "API key is missing. Please provide a valid API key."
        case .invalidBaseURL:
            return "Invalid base URL. Please check your configuration."
            
        // Generic Errors
        case .cancelled:
            return "Operation was cancelled."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recovery Suggestion
    
    /// Suggested action for the user to recover from the error
    public var recoverySuggestion: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .requestTimeout:
            return "Check your internet connection or try again later."
        case .serverError:
            return "Wait a moment and try again. If the problem persists, contact support."
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Wait \(Int(retryAfter)) seconds before trying again."
            }
            return "Wait a few moments before trying again."
            
        // Authentication Errors
        case .unauthorized, .invalidCredentials:
            return "Verify your credentials and try again."
        case .sessionExpired, .verificationExpired:
            return "Start a new verification session."
            
        // Document Errors
        case .documentBlurry, .documentNotDetected:
            return "Take a new photo ensuring good lighting and focus."
        case .glareDetected:
            return "Avoid direct light on the document and try again."
        case .documentTooLarge:
            return "Reduce the image quality or resolution and try again."
            
        // Liveness Errors
        case .faceNotDetected, .multipleFacesDetected, .faceTooClose, .faceTooFar, .faceNotCentered:
            return "Follow the on-screen instructions and try again."
        case .poorLighting:
            return "Move to a well-lit area and try again."
            
        // NFC Errors
        case .nfcTagConnectionLost:
            return "Hold your device steady against the passport and try again."
        case .nfcInvalidCredentials:
            return "Double-check the document number, date of birth, and expiry date."
        case .nfcTimeout:
            return "Ensure your device is close to the passport and try again."
            
        // Camera Errors
        case .cameraPermissionDenied:
            return "Go to Settings > Privacy > Camera and enable access for this app."
        case .cameraNotAvailable:
            return "Close other apps using the camera and try again."
            
        // Storage Errors
        case .storageQuotaExceeded:
            return "Free up storage space on your device."
            
        default:
            return "Try again. If the problem persists, contact support."
        }
    }
    
    // MARK: - Error Category
    
    /// Category of the error for logging and analytics
    public var category: OkIDErrorCategory {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError, .invalidResponse, .rateLimitExceeded:
            return .network
        case .unauthorized, .invalidCredentials, .sessionExpired, .invalidAPIKey:
            return .authentication
        case .verificationNotFound, .verificationExpired, .verificationAlreadyCompleted, 
             .invalidVerificationState, .moduleNotAvailable:
            return .validation
        case .documentUploadFailed, .invalidDocumentFormat, .documentTooLarge, .documentBlurry, 
             .documentNotDetected, .invalidDocumentSide, .glareDetected, .documentExpired:
            return .document
        case .faceNotDetected, .multipleFacesDetected, .faceTooClose, .faceTooFar, 
             .faceNotCentered, .poorLighting, .livenessCheckFailed:
            return .liveness
        case .nfcNotSupported, .nfcNotEnabled, .nfcTagConnectionLost, .nfcAuthenticationFailed, 
             .nfcInvalidCredentials, .nfcDataGroupNotFound, .nfcInvalidMRZ, .nfcUnsupportedDocument, 
             .nfcTimeout, .nfcUserCancelled:
            return .nfc
        case .qrCodeInvalidURL, .qrCodeUnsupportedOrigin, .qrCodeMissingData, .qrCodeInvalidFormat:
            return .qrCode
        case .cameraPermissionDenied, .cameraNotAvailable, .cameraInitializationFailed:
            return .camera
        case .storageWriteFailed, .storageReadFailed, .storageQuotaExceeded, .dataCorrupted:
            return .storage
        case .invalidFormData, .requiredFieldMissing, .invalidFieldFormat:
            return .form
        case .imageProcessingFailed, .faceDetectionFailed, .biometricProcessingFailed, .modelLoadFailed:
            return .processing
        case .invalidConfiguration, .missingAPIKey, .invalidBaseURL:
            return .configuration
        case .cancelled:
            return .userAction
        case .unknown:
            return .unknown
        }
    }
    
    // MARK: - Is Recoverable
    
    /// Whether this error can potentially be recovered from by retrying
    public var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .serverError, .rateLimitExceeded,
             .documentBlurry, .documentNotDetected, .glareDetected,
             .faceNotDetected, .multipleFacesDetected, .faceTooClose, .faceTooFar, 
             .faceNotCentered, .poorLighting,
             .nfcTagConnectionLost, .nfcTimeout,
             .cameraNotAvailable, .cameraInitializationFailed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Requires User Action
    
    /// Whether this error requires explicit user action to resolve
    public var requiresUserAction: Bool {
        switch self {
        case .cameraPermissionDenied, .nfcNotEnabled, .storageQuotaExceeded,
             .documentExpired, .verificationExpired, .sessionExpired,
             .invalidCredentials, .nfcInvalidCredentials:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: OkIDError, rhs: OkIDError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.requestTimeout, .requestTimeout),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.invalidCredentials, .invalidCredentials),
             (.sessionExpired, .sessionExpired),
             (.invalidAPIKey, .invalidAPIKey),
             (.verificationNotFound, .verificationNotFound),
             (.verificationExpired, .verificationExpired),
             (.verificationAlreadyCompleted, .verificationAlreadyCompleted),
             (.cancelled, .cancelled):
            return true
        case (.serverError(let lCode, let lMsg), .serverError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.rateLimitExceeded(let lRetry), .rateLimitExceeded(let rRetry)):
            return lRetry == rRetry
        default:
            return false
        }
    }
}

// MARK: - Error Category

public enum OkIDErrorCategory: String {
    case network
    case authentication
    case validation
    case document
    case liveness
    case nfc
    case qrCode
    case camera
    case storage
    case form
    case processing
    case configuration
    case userAction
    case unknown
}

// MARK: - Error Conversion Helpers

extension OkIDError {
    
    /// Convert from OkIDAPIError
    public static func from(_ apiError: OkIDAPIError) -> OkIDError {
        switch apiError {
        case .invalidResponse:
            return .invalidResponse
        case .httpError(let statusCode):
            if statusCode == 401 {
                return .unauthorized
            } else if statusCode == 404 {
                return .verificationNotFound
            } else if statusCode == 429 {
                return .rateLimitExceeded(retryAfter: nil)
            } else if statusCode >= 500 {
                return .serverError(statusCode: statusCode, message: nil)
            }
            return .serverError(statusCode: statusCode, message: nil)
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                if nsError.code == NSURLErrorNotConnectedToInternet || 
                   nsError.code == NSURLErrorNetworkConnectionLost {
                    return .networkUnavailable
                } else if nsError.code == NSURLErrorTimedOut {
                    return .requestTimeout
                }
            }
            return .unknown(error)
        case .decodingError(let error):
            return .invalidResponse
        }
    }
    
    /// Convert from OkIDNFCReadError
    public static func from(_ nfcError: OkIDNFCReadError) -> OkIDError {
        switch nfcError {
        case .nfcNotSupported:
            return .nfcNotSupported
        case .tagConnectionLost:
            return .nfcTagConnectionLost
        case .invalidCredentials:
            return .nfcInvalidCredentials
        case .authenticationFailed:
            return .nfcAuthenticationFailed
        case .dataGroupNotFound(let group):
            return .nfcDataGroupNotFound(group: group)
        case .invalidMRZ:
            return .nfcInvalidMRZ
        case .unsupportedDocument:
            return .nfcUnsupportedDocument
        case .userCancelled:
            return .nfcUserCancelled
        case .timeout:
            return .nfcTimeout
        case .unknown(let error):
            return .unknown(error)
        }
    }
    
    /// Convert from OkIDQRParseError
    public static func from(_ qrError: OkIDQRParseError) -> OkIDError {
        switch qrError {
        case .invalidURL:
            return .qrCodeInvalidURL
        case .unsupportedOrigin:
            return .qrCodeUnsupportedOrigin
        case .missingVerificationId:
            return .qrCodeMissingData
        case .invalidFormat:
            return .qrCodeInvalidFormat
        }
    }
}
