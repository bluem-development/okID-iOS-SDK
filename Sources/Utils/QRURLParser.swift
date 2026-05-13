import Foundation

/// QR URL Parser for v2client portal QR codes
public class QRURLParser {
    
    private let allowedOrigins: [String]?
    
    public init(allowedOrigins: [String]? = nil) {
        self.allowedOrigins = allowedOrigins
    }
    
    /// Parse QR code URL
    public func parse(url: String) -> Result<OkIDQRParseResult, OkIDQRParseError> {
        guard let urlComponents = URLComponents(string: url) else {
            return .failure(.invalidURL)
        }
        
        guard let scheme = urlComponents.scheme,
              let host = urlComponents.host,
              ["http", "https"].contains(scheme) else {
            return .failure(.invalidURL)
        }
        
        let origin = "\(scheme)://\(host)"
        if let port = urlComponents.port {
            // origin += ":\(port)" // Optionally include port
        }
        
        // Validate origin if allowed origins specified
        if let allowed = allowedOrigins, !allowed.isEmpty {
            let normalizedOrigin = origin.lowercased()
            let isAllowed = allowed.contains { allowedOrigin in
                normalizedOrigin.hasPrefix(allowedOrigin.lowercased())
            }
            
            guard isAllowed else {
                return .failure(.unsupportedOrigin)
            }
        }
        
        // Extract query parameters
        let queryItems = urlComponents.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        
        // Check for desktop session ID
        let desktopSessionId = params["session_id"]
        
        // Parse path to determine if it's generate or verify flow
        let path = urlComponents.path
        
        if path.contains("/generate") {
            // Generate flow - no verification ID yet
            return .success(OkIDQRParseResult(
                origin: origin,
                verificationId: nil,
                desktopSessionId: desktopSessionId,
                isGenerateFlow: true
            ))
        } else if path.contains("/verify") {
            // Verify flow - extract verification ID
            let pathComponents = path.components(separatedBy: "/")
            if let verifyIndex = pathComponents.firstIndex(of: "verify"),
               verifyIndex + 1 < pathComponents.count {
                let verificationId = pathComponents[verifyIndex + 1]
                
                return .success(OkIDQRParseResult(
                    origin: origin,
                    verificationId: verificationId,
                    desktopSessionId: desktopSessionId,
                    isGenerateFlow: false
                ))
            } else {
                return .failure(.missingVerificationId)
            }
        } else {
            return .failure(.invalidFormat)
        }
    }
}

