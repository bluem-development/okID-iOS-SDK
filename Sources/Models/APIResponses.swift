import Foundation

// MARK: - Generate Verification Response

public struct OkIDGenerateVerificationResponse: Codable {
    public let verificationId: String
    public let expiresAt: String
    public let flow: [String]
    public let modules: [String: Any]
    public let rapidMode: Bool
    
    enum CodingKeys: String, CodingKey {
        case verificationId = "verificationId"
        case expiresAt = "expiresAt"
        case flow = "flow"
        case modules = "modules"
        case rapidMode = "rapidMode"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verificationId = try container.decode(String.self, forKey: .verificationId)
        expiresAt = try container.decode(String.self, forKey: .expiresAt)
        flow = try container.decode([String].self, forKey: .flow)
        
        // Decode modules as dictionary
        if let modulesDict = try? container.decode([String: AnyCodable].self, forKey: .modules) {
            modules = modulesDict.mapValues { $0.value }
        } else {
            modules = [:]
        }
        
        rapidMode = try container.decodeIfPresent(Bool.self, forKey: .rapidMode) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verificationId, forKey: .verificationId)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(flow, forKey: .flow)
        try container.encode(rapidMode, forKey: .rapidMode)
        
        // Encode modules
        let modulesDict = modules.mapValues { AnyCodable($0) }
        try container.encode(modulesDict, forKey: .modules)
    }
}

// MARK: - Start Verification Response

public struct OkIDStartVerificationResponse: Codable {
    public let verificationId: String
    public let status: String
    public let nextStep: String?
    
    enum CodingKeys: String, CodingKey {
        case verificationId = "verification_id"
        case status
        case nextStep = "next_step"
    }
}

// MARK: - Module Completion Response

public struct OkIDModuleCompletionResponse: Codable {
    public let module: String
    public let status: String
    public let nextStep: String?
    
    enum CodingKeys: String, CodingKey {
        case module = "module"
        case status = "status"
        case nextStep = "next_step"
    }
}

// MARK: - Document Metrics

public struct OkIDDocumentMetrics: Codable {
    public let blurrinessScore: Double?
    public let side: String?
    public let isDocumentCompleteAfterUpload: Bool?
    public let rawMrz: [String]?
    
    enum CodingKeys: String, CodingKey {
        case blurrinessScore = "blurriness_score"
        case side
        case isDocumentCompleteAfterUpload = "is_document_complete_after_upload"
        case rawMrz = "raw_mrz"
    }
}

// MARK: - Document Attempt Details

public struct OkIDDocumentAttemptDetails: Codable {
    public let attemptId: String
    public let status: String
    public let reasonCode: String?
    public let message: String?
    public let metrics: OkIDDocumentMetrics?
    
    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case status
        case reasonCode = "reason_code"
        case message
        case metrics
    }
}

// MARK: - Document Module Response

public struct OkIDDocumentModuleResponse: Codable {
    public let module: String
    public let status: String
    public let nextStep: String?
    public let attemptResult: OkIDDocumentAttemptDetails
    
    enum CodingKeys: String, CodingKey {
        case module
        case status
        case nextStep = "next_step"
        case attemptResult = "attempt_result"
    }
}

// MARK: - Form Answer

public struct OkIDFormAnswer: Codable {
    public let questionId: String
    public let answer: AnyCodable
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case answer
    }
    
    public init(questionId: String, answer: Any) {
        self.questionId = questionId
        self.answer = AnyCodable(answer)
    }
}

// MARK: - Validation Response

public struct OkIDValidationResponse: Codable {
    public let verificationId: String
    public let status: String
    public let reason: String?
    public let exportedData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case verificationId = "verification_id"
        case status
        case reason
        case exportedData = "exported_data"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        verificationId = try container.decode(String.self, forKey: .verificationId)
        status = try container.decode(String.self, forKey: .status)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        
        if let exportedDict = try? container.decode([String: AnyCodable].self, forKey: .exportedData) {
            exportedData = exportedDict.mapValues { $0.value }
        } else {
            exportedData = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(verificationId, forKey: .verificationId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(reason, forKey: .reason)
        
        if let data = exportedData {
            let dataDict = data.mapValues { AnyCodable($0) }
            try container.encode(dataDict, forKey: .exportedData)
        }
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

