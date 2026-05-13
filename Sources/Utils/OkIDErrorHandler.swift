import Foundation
import UIKit

// MARK: - Error Handler

/// Centralized error handling and logging
public class OkIDErrorHandler {
    
    public static let shared = OkIDErrorHandler()
    
    private let logger = Logger.error
    private var errorListeners: [(OkIDError) -> Void] = []
    
    private init() {}
    
    // MARK: - Error Handling
    
    /// Handle an error with logging and optional user notification
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Context information about where the error occurred
    ///   - severity: Severity level of the error
    public func handle(_ error: Error, context: String? = nil, severity: ErrorSeverity = .error) {
        let okidError = normalize(error)
        
        // Log the error
        logError(okidError, context: context, severity: severity)
        
        // Notify listeners
        errorListeners.forEach { $0(okidError) }
    }
    
    /// Normalize any error to OkIDError
    /// - Parameter error: The error to normalize
    /// - Returns: OkIDError instance
    public func normalize(_ error: Error) -> OkIDError {
        if let okidError = error as? OkIDError {
            return okidError
        } else if let apiError = error as? OkIDAPIError {
            return OkIDError.from(apiError)
        } else if let nfcError = error as? OkIDNFCReadError {
            return OkIDError.from(nfcError)
        } else if let qrError = error as? OkIDQRParseError {
            return OkIDError.from(qrError)
        } else {
            let nsError = error as NSError
            
            // Check for network errors
            if nsError.domain == NSURLErrorDomain {
                if nsError.code == NSURLErrorNotConnectedToInternet || 
                   nsError.code == NSURLErrorNetworkConnectionLost {
                    return .networkUnavailable
                } else if nsError.code == NSURLErrorTimedOut {
                    return .requestTimeout
                } else if nsError.code == NSURLErrorCancelled {
                    return .cancelled
                }
            }
            
            // Check for file system errors
            if nsError.domain == NSCocoaErrorDomain {
                if nsError.code == NSFileWriteOutOfSpaceError {
                    return .storageQuotaExceeded
                } else if nsError.code == NSFileWriteNoPermissionError {
                    return .storageWriteFailed
                } else if nsError.code == NSFileReadNoPermissionError {
                    return .storageReadFailed
                }
            }
            
            return .unknown(error)
        }
    }
    
    // MARK: - Logging
    
    private func logError(_ error: OkIDError, context: String?, severity: ErrorSeverity) {
        let contextStr = context.map { " [\($0)]" } ?? ""
        let message = "\(severity.emoji) \(error.category.rawValue.uppercased())\(contextStr): \(error.errorDescription ?? "Unknown error")"
        
        switch severity {
        case .debug:
            logger.debug(message)
        case .warning:
            logger.warning(message)
        case .error:
            logger.error(message)
        case .critical:
            logger.error("🔴 CRITICAL: \(message)")
        }
        
        // Log recovery suggestion if available
        if let suggestion = error.recoverySuggestion {
            logger.debug("💡 Recovery suggestion: \(suggestion)")
        }
    }
    
    // MARK: - Error Listeners
    
    /// Add a listener for error events
    /// - Parameter listener: Closure called when an error occurs
    public func addErrorListener(_ listener: @escaping (OkIDError) -> Void) {
        errorListeners.append(listener)
    }
    
    /// Remove all error listeners
    public func removeAllListeners() {
        errorListeners.removeAll()
    }
    
    // MARK: - User Presentation
    
    /// Present error to user with an alert
    /// - Parameters:
    ///   - error: The error to present
    ///   - from: View controller to present from
    ///   - onRetry: Optional retry action
    ///   - onDismiss: Optional dismiss action
    @MainActor
    public func presentError(
        _ error: Error,
        from viewController: UIViewController,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let okidError = normalize(error)
        let title = getErrorTitle(for: okidError)
        let message = okidError.errorDescription ?? "An error occurred"
        
        if okidError.isRecoverable && onRetry != nil {
            OkIDAlert.showConfirmation(
                title: title,
                message: message,
                confirmTitle: "Retry",
                confirmStyle: .default,
                from: viewController,
                onConfirm: {
                    onRetry?()
                },
                onCancel: {
                    onDismiss?()
                }
            )
        } else {
            OkIDAlert.show(
                title: title,
                message: message,
                from: viewController
            )
            
            // Delay dismiss callback slightly to allow alert to show
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onDismiss?()
            }
        }
    }
    
    private func getErrorTitle(for error: OkIDError) -> String {
        switch error.category {
        case .network:
            return "Connection Error"
        case .authentication:
            return "Authentication Error"
        case .validation:
            return "Verification Error"
        case .document:
            return "Document Error"
        case .liveness:
            return "Selfie Error"
        case .nfc:
            return "NFC Reading Error"
        case .qrCode:
            return "QR Code Error"
        case .camera:
            return "Camera Error"
        case .storage:
            return "Storage Error"
        case .form:
            return "Form Error"
        case .processing:
            return "Processing Error"
        case .configuration:
            return "Configuration Error"
        case .userAction:
            return "Action Required"
        case .unknown:
            return "Error"
        }
    }
}

// MARK: - Error Severity

public enum ErrorSeverity {
    case debug
    case warning
    case error
    case critical
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔴"
        }
    }
}

// MARK: - Result Extension

extension Result where Failure == Error {
    
    /// Handle result with automatic error handling
    /// - Parameters:
    ///   - context: Context information
    ///   - onSuccess: Success handler
    ///   - onFailure: Failure handler (optional, defaults to error handler)
    public func handle(
        context: String? = nil,
        onSuccess: (Success) -> Void,
        onFailure: ((OkIDError) -> Void)? = nil
    ) {
        switch self {
        case .success(let value):
            onSuccess(value)
        case .failure(let error):
            let okidError = OkIDErrorHandler.shared.normalize(error)
            OkIDErrorHandler.shared.handle(error, context: context)
            onFailure?(okidError)
        }
    }
}

// MARK: - Async Error Handling

extension Task where Failure == Error {
    
    /// Execute async operation with error handling
    /// - Parameters:
    ///   - context: Context information
    ///   - operation: The async operation
    ///   - onError: Error handler
    /// - Returns: Task result
    @discardableResult
    public static func catching(
        context: String? = nil,
        operation: @escaping () async throws -> Success,
        onError: ((OkIDError) -> Void)? = nil
    ) -> Task {
        Task {
            do {
                return try await operation()
            } catch {
                let okidError = OkIDErrorHandler.shared.normalize(error)
                OkIDErrorHandler.shared.handle(error, context: context)
                onError?(okidError)
                throw okidError
            }
        }
    }
}
