import Foundation
import os.log

/// Centralized logging utility for OkIDVerificationSDK.
/// Supports configurable minimum log level. Default: `.error` (only errors printed).
/// Set `Logger.minimumLevel = .debug` to see all logs during development.
struct Logger {
    
    /// Global flag to enable/disable all logging
    static var isEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// Minimum log level to print. Messages below this level are silently discarded.
    /// Default is `.error` — only errors are printed.
    /// Set to `.debug` to see everything, `.info` to skip debug, `.warning` for warnings+errors only.
    public static var minimumLevel: Level = .error
    
    /// Log levels (ordered by severity)
    enum Level: Int, Comparable {
        case debug   = 0
        case info    = 1
        case warning = 2
        case error   = 3
        
        var prefix: String {
            switch self {
            case .debug:   return "🔍"
            case .info:    return "ℹ️"
            case .warning: return "⚠️"
            case .error:   return "❌"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .debug:   return .debug
            case .info:    return .info
            case .warning: return .default
            case .error:   return .error
            }
        }
        
        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    private let subsystem = "io.okid.verification"
    private let category: String
    
    init(category: String) {
        self.category = category
    }
    
    /// Log a message if it meets the minimum level threshold.
    func log(_ message: String, level: Level = .debug) {
        guard Logger.isEnabled, level >= Logger.minimumLevel else { return }
        
        if #available(iOS 14.0, *) {
            let logger = os.Logger(subsystem: subsystem, category: category)
            logger.log(level: level.osLogType, "\(level.prefix) [\(self.category)] \(message)")
        } else {
            print("\(level.prefix) [\(category)] \(message)")
        }
    }
    
    /// Debug log (most verbose)
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    /// Info log
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    /// Warning log
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    /// Error log (always printed when logging is enabled)
    func error(_ message: String) {
        log(message, level: .error)
    }
}

/// Global logger instances for common categories
extension Logger {
    static let camera = Logger(category: "Camera")
    static let yolo = Logger(category: "YOLO")
    static let nfc = Logger(category: "NFC")
    static let api = Logger(category: "API")
    static let flow = Logger(category: "Flow")
    static let document = Logger(category: "Document")
    static let liveness = Logger(category: "Liveness")
    static let validation = Logger(category: "Validation")
    static let profile = Logger(category: "Profile")
    static let qr = Logger(category: "QR")
    static let mrz = Logger(category: "MRZ")
    static let blur = Logger(category: "Blur")
    static let face = Logger(category: "Face")
    static let formData = Logger(category: "FormData")
    static let terms = Logger(category: "Terms")
    static let storage = Logger(category: "Storage")
    static let error = Logger(category: "Error")
}
