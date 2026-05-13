import Foundation

/// Desktop notifier for SSE notifications to v2client portal
public class DesktopNotifier {
    
    private let portalBaseUrl: String
    private let desktopSessionId: String?
    private let session: URLSession
    
    public init(portalBaseUrl: String, desktopSessionId: String?) {
        self.portalBaseUrl = portalBaseUrl.hasSuffix("/") 
            ? String(portalBaseUrl.dropLast()) 
            : portalBaseUrl
        self.desktopSessionId = desktopSessionId
        self.session = URLSession.shared
    }
    
    /// Notify desktop that mobile has connected
    public func notifyMobileAccess(verificationId: String) async throws {
        guard let sessionId = desktopSessionId else { return }
        
        let url = URL(string: "\(portalBaseUrl)/api/sse/mobile-connected")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "desktop_session_id": sessionId,
            "verification_id": verificationId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DesktopNotifierError.notificationFailed
        }
    }
    
    /// Notify desktop that verification is complete
    public func notifyVerificationComplete(verificationId: String, status: String) async throws {
        guard let sessionId = desktopSessionId else { return }
        
        let url = URL(string: "\(portalBaseUrl)/api/sse/verification-complete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "desktop_session_id": sessionId,
            "verification_id": verificationId,
            "status": status
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DesktopNotifierError.notificationFailed
        }
    }
}

// MARK: - Desktop Notifier Error

public enum DesktopNotifierError: Error, LocalizedError {
    case notificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .notificationFailed:
            return "Failed to send notification to desktop"
        }
    }
}

