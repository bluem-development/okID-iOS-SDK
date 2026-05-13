import Foundation

// MARK: - QR Parse Result

public struct OkIDQRParseResult {
    public let origin: String
    public let verificationId: String?
    public let desktopSessionId: String?
    public let isGenerateFlow: Bool
    
    public init(
        origin: String,
        verificationId: String? = nil,
        desktopSessionId: String? = nil,
        isGenerateFlow: Bool = false
    ) {
        self.origin = origin
        self.verificationId = verificationId
        self.desktopSessionId = desktopSessionId
        self.isGenerateFlow = isGenerateFlow
    }
}

// MARK: - QR Scan Result

public struct OkIDQRScanResult {
    public let parseResult: OkIDQRParseResult
    public let rawUrl: String
    
    public var origin: String { parseResult.origin }
    public var verificationId: String? { parseResult.verificationId }
    public var desktopSessionId: String? { parseResult.desktopSessionId }
    public var isGenerateFlow: Bool { parseResult.isGenerateFlow }
    
    public init(parseResult: OkIDQRParseResult, rawUrl: String) {
        self.parseResult = parseResult
        self.rawUrl = rawUrl
    }
}

// MARK: - QR Parse Error

public enum OkIDQRParseError: Error, LocalizedError {
    case invalidURL
    case unsupportedOrigin
    case missingVerificationId
    case invalidFormat
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid QR code URL"
        case .unsupportedOrigin:
            return "This QR code is from an unsupported origin"
        case .missingVerificationId:
            return "No verification ID found in QR code"
        case .invalidFormat:
            return "QR code format is not recognized"
        }
    }
}

