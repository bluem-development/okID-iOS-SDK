import Foundation

/// API Client for verification backend
public class VerificationAPIClient {
    
    private let config: OkIDSDKConfig
    private let session: URLSession
    private var verificationId: String?
    
    public init(config: OkIDSDKConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout
        self.session = URLSession(configuration: configuration)
    }
    
    public func setVerificationId(_ id: String) {
        self.verificationId = id
    }
    
    // MARK: - Generate Verification
    
    public func generateVerification(portalBaseUrl: String, locale: String = "en") async throws -> OkIDGenerateVerificationResponse {
        let normalizedUrl = portalBaseUrl.hasSuffix("/") 
            ? String(portalBaseUrl.dropLast()) 
            : portalBaseUrl
        
        let url = URL(string: "\(normalizedUrl)/api/generate-verification")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["locale": locale]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDGenerateVerificationResponse.self, from: data)
    }
    
    // MARK: - Start Verification
    
    public func startVerification(
        verificationId: String,
        locale: String? = nil,
        clientMetadata: [String: Any]? = nil
    ) async throws -> OkIDStartVerificationResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [:]
        if let locale = locale {
            body["locale"] = locale
        }
        if let metadata = clientMetadata {
            body["client_metadata"] = metadata
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDStartVerificationResponse.self, from: data)
    }
    
    // MARK: - Accept Terms
    
    public func acceptTerms(verificationId: String) async throws -> OkIDModuleCompletionResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/terms")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDModuleCompletionResponse.self, from: data)
    }
    
    // MARK: - Upload Document
    
    public func uploadDocument(
        verificationId: String,
        imageData: Data,
        side: String? = nil,
        blurrinessScore: Double? = nil,
        attemptId: String? = nil
    ) async throws -> OkIDDocumentModuleResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/document")!
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let finalAttemptId = attemptId ?? UUID().uuidString
        var metadata: [String: Any] = ["attempt_id": finalAttemptId]
        if let side = side {
            metadata["side"] = side
        }
        if let score = blurrinessScore {
            metadata["blurriness_score"] = score
        }
        
        var body = Data()
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"document\"; filename=\"document.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\r\n\r\n".data(using: .utf8)!)
        let metadataJson = try JSONSerialization.data(withJSONObject: metadata)
        body.append(metadataJson)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDDocumentModuleResponse.self, from: data)
    }
    
    // MARK: - Upload Selfie
    
    public func uploadSelfie(
        verificationId: String,
        imageData: Data,
        biometricData: [String: Any]? = nil
    ) async throws -> OkIDModuleCompletionResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/liveness")!
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"selfie\"; filename=\"selfie.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add metadata
        if let metadata = biometricData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"metadata_json\"\r\n\r\n".data(using: .utf8)!)
            let metadataJson = try JSONSerialization.data(withJSONObject: metadata)
            body.append(metadataJson)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDModuleCompletionResponse.self, from: data)
    }
    
    // MARK: - Submit Form Data
    
    public func submitFormData(
        verificationId: String,
        answers: [OkIDFormAnswer]
    ) async throws -> OkIDModuleCompletionResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/form_data")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let answersData = try encoder.encode(answers)
        let answersArray = try JSONSerialization.jsonObject(with: answersData) as! [[String: Any]]
        
        let body = ["answers": answersArray]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDModuleCompletionResponse.self, from: data)
    }
    
    // MARK: - Submit NFC Data
    
    public func submitNfcData(
        verificationId: String,
        passportData: OkIDPassportData,
        metadata: [String: Any],
        photo: Data? = nil
    ) async throws -> OkIDModuleCompletionResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/nfc")!
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Build NFC data JSON
        let nfcData = buildNfcDataJson(passportData: passportData, metadata: metadata)
        let nfcJson = try JSONSerialization.data(withJSONObject: nfcData)
        
        // Add NFC data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"nfc_data\"\r\n\r\n".data(using: .utf8)!)
        body.append(nfcJson)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add photo if available
        if let photoData = photo {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"passport_photo.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(photoData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDModuleCompletionResponse.self, from: data)
    }
    
    // MARK: - Validate Verification
    
    public func validateVerification(verificationId: String) async throws -> OkIDValidationResponse {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/validate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(OkIDValidationResponse.self, from: data)
    }
    
    // MARK: - Reset Document Module
    
    public func resetDocumentModule(verificationId: String) async throws {
        let url = URL(string: "\(config.baseUrl)/v2/verification/\(verificationId)/module/document/reset")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [:])
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Helpers
    
    private func buildNfcDataJson(passportData: OkIDPassportData, metadata: [String: Any]) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        var mrz: [String: Any?] = [:]
        if let info = passportData.personalInfo {
            mrz["document_type"] = info.documentType
            mrz["issuing_state"] = info.issuingState
            mrz["document_number"] = info.documentNumber
            mrz["last_name"] = info.lastName
            mrz["first_name"] = info.firstName
            mrz["nationality"] = info.nationality
            mrz["date_of_birth"] = info.dateOfBirth.map { formatter.string(from: $0) }
            mrz["gender"] = info.gender
            mrz["date_of_expiry"] = info.dateOfExpiry.map { formatter.string(from: $0) }
            mrz["optional_data_1"] = info.optionalData1
            mrz["optional_data_2"] = info.optionalData2
        }
        
        return [
            "mrz": mrz.compactMapValues { $0 },
            "data_groups_read": passportData.dataGroupsRead,
            "sod_present": passportData.additionalInfo?["sod"] != nil,
            "metadata": metadata
        ]
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OkIDAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Extract retry-after header for rate limiting
            if httpResponse.statusCode == 429,
               let retryAfterStr = httpResponse.value(forHTTPHeaderField: "Retry-After"),
               let retryAfter = TimeInterval(retryAfterStr) {
                throw OkIDError.rateLimitExceeded(retryAfter: retryAfter)
            }
            
            throw OkIDAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Error Handling
    
    /// Wrap API call with error handling
    private func handleAPICall<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as OkIDError {
            throw error
        } catch let error as OkIDAPIError {
            throw OkIDError.from(error)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                if nsError.code == NSURLErrorNotConnectedToInternet || 
                   nsError.code == NSURLErrorNetworkConnectionLost {
                    throw OkIDError.networkUnavailable
                } else if nsError.code == NSURLErrorTimedOut {
                    throw OkIDError.requestTimeout
                } else if nsError.code == NSURLErrorCancelled {
                    throw OkIDError.cancelled
                }
            }
            throw OkIDError.unknown(error)
        }
    }
}

// MARK: - API Error

public enum OkIDAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

