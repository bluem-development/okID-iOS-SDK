import Foundation

// MARK: - Module Status

public enum OkIDModuleStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case skipped
}

// MARK: - Verification Status

public enum OkIDVerificationStatus: String, Codable {
    case generated
    case initiated
    case inProgress = "in_progress"
    case validating
    case verified
    case rejected
    case needsManualReview = "needs_manual_review"
    case needsTemplate = "needs_template"
    case expired
    case junk
}

// MARK: - Document Attempt Status

public enum OkIDDocumentAttemptStatus: String, Codable {
    case accepted
    case rejected
}

// MARK: - Verification Configuration

public struct OkIDVerificationConfig: Codable {
    public let retentionDays: Int
    public let dueDays: Int
    public let modules: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case retentionDays = "retention_days"
        case dueDays = "due_days"
        case modules
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        retentionDays = try container.decode(Int.self, forKey: .retentionDays)
        dueDays = try container.decode(Int.self, forKey: .dueDays)
        modules = try container.decode([String: Any].self, forKey: .modules)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(retentionDays, forKey: .retentionDays)
        try container.encode(dueDays, forKey: .dueDays)
        try container.encode(modules, forKey: .modules)
    }
}

// MARK: - Verification Status Info

public struct OkIDVerificationStatusInfo: Codable {
    public let current: OkIDVerificationStatus
    public let updatedAt: String
    public let progress: [String: OkIDModuleStatus]
    public let rejectionReason: String?
    public let reviewNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case current
        case updatedAt = "updated_at"
        case progress
        case rejectionReason = "rejection_reason"
        case reviewNotes = "review_notes"
    }
}

// MARK: - OCR Text Line

public struct OkIDOcrTextLine: Codable {
    public let text: String
    public let confidence: Double
    public let coordinates: [[Double]]
}

// MARK: - MRZ Data

public struct OkIDMrzData: Codable {
    public let mrzType: String?
    public let validScore: Double
    public let mrzLines: [String]
    public let formatValidation: String
    
    enum CodingKeys: String, CodingKey {
        case mrzType = "mrz_type"
        case validScore = "valid_score"
        case mrzLines = "mrz_lines"
        case formatValidation = "format_validation"
    }
}

// MARK: - Document Attempt Record

public struct OkIDDocumentAttemptRecord: Codable {
    public let attemptId: String
    public let status: OkIDDocumentAttemptStatus
    public let reasonCode: String?
    public let message: String?
    public let metrics: [String: Any]?
    public let imagePath: String?
    public let detectionResults: [String: Any]?
    public let ocrText: [OkIDOcrTextLine]?
    public let mrzData: OkIDMrzData?
    public let templateData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case status
        case reasonCode = "reason_code"
        case message
        case metrics
        case imagePath = "image_path"
        case detectionResults = "detection_results"
        case ocrText = "ocr_text"
        case mrzData = "mrz_data"
        case templateData = "template_data"
    }
    
    public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            attemptId = try container.decode(String.self, forKey: .attemptId)
            status = try container.decode(OkIDDocumentAttemptStatus.self, forKey: .status)
            reasonCode = try container.decodeIfPresent(String.self, forKey: .reasonCode)
            message = try container.decodeIfPresent(String.self, forKey: .message)
            metrics = try container.decodeIfPresent([String: Any].self, forKey: .metrics)
            imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
            detectionResults = try container.decodeIfPresent([String: Any].self, forKey: .detectionResults)
            ocrText = try container.decodeIfPresent([OkIDOcrTextLine].self, forKey: .ocrText)
            mrzData = try container.decodeIfPresent(OkIDMrzData.self, forKey: .mrzData)
            templateData = try container.decodeIfPresent([String: Any].self, forKey: .templateData)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(attemptId, forKey: .attemptId)
            try container.encode(status, forKey: .status)
            try container.encodeIfPresent(reasonCode, forKey: .reasonCode)
            try container.encodeIfPresent(message, forKey: .message)
            try container.encodeIfPresent(metrics, forKey: .metrics)
            try container.encodeIfPresent(imagePath, forKey: .imagePath)
            try container.encodeIfPresent(detectionResults, forKey: .detectionResults)
            try container.encodeIfPresent(ocrText, forKey: .ocrText)
            try container.encodeIfPresent(mrzData, forKey: .mrzData)
            try container.encodeIfPresent(templateData, forKey: .templateData)
        }
}

// MARK: - Document Side Result

public struct OkIDDocumentSideResult: Codable {
    public let imagePath: String
    public let templateData: [String: Any]?
    public let mrzData: OkIDMrzData?
    public let determinationSource: String?
    public let determinationDetails: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case imagePath = "image_path"
        case templateData = "template_data"
        case mrzData = "mrz_data"
        case determinationSource = "determination_source"
        case determinationDetails = "determination_details"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        templateData = try container.decodeIfPresent([String: Any].self, forKey: .templateData)
        mrzData = try container.decodeIfPresent(OkIDMrzData.self, forKey: .mrzData)
        determinationSource = try container.decodeIfPresent(String.self, forKey: .determinationSource)
        determinationDetails = try container.decodeIfPresent([String: Any].self, forKey: .determinationDetails)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encodeIfPresent(templateData, forKey: .templateData)
        try container.encodeIfPresent(mrzData, forKey: .mrzData)
        try container.encodeIfPresent(determinationSource, forKey: .determinationSource)
        try container.encodeIfPresent(determinationDetails, forKey: .determinationDetails)
    }
}

// MARK: - Document Results

public struct OkIDDocumentResults: Codable {
    public let documentType: String?
    public let front: OkIDDocumentSideResult?
    public let back: OkIDDocumentSideResult?
    
    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case front
        case back
    }
}

// MARK: - Document Data

public struct OkIDDocumentData: Codable {
    public let attempts: [OkIDDocumentAttemptRecord]
    public let results: OkIDDocumentResults?
}

// MARK: - Verification Data

public struct OkIDVerificationData: Codable {
    public let document: OkIDDocumentData?
    public let liveness: [String: Any]?
    public let terms: [String: Any]?
    public let formData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case document
        case liveness
        case terms
        case formData = "form_data"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        document = try container.decodeIfPresent(OkIDDocumentData.self, forKey: .document)
        liveness = try container.decodeIfPresent([String: Any].self, forKey: .liveness)
        terms = try container.decodeIfPresent([String: Any].self, forKey: .terms)
        formData = try container.decodeIfPresent([String: Any].self, forKey: .formData)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(document, forKey: .document)
        try container.encodeIfPresent(liveness, forKey: .liveness)
        try container.encodeIfPresent(terms, forKey: .terms)
        try container.encodeIfPresent(formData, forKey: .formData)
    }
}

// MARK: - Timeline Event

public struct OkIDTimelineEvent: Codable {
    public let timestamp: String
    public let type: String
    public let module: String?
    public let details: [String: Any]
    
    enum CodingKeys: String, CodingKey {
            case timestamp
            case type
            case module
            case details
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            timestamp = try container.decode(String.self, forKey: .timestamp)
            type = try container.decode(String.self, forKey: .type)
            module = try container.decodeIfPresent(String.self, forKey: .module)
            details = try container.decode([String: Any].self, forKey: .details)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(module, forKey: .module)
            try container.encode(details, forKey: .details)
        }
}

// MARK: - Verification Metadata

public struct OkIDVerificationMetadata: Codable {
    public let userAgent: String?
    public let ipAddress: String?
    public let frontendIp: String?
    public let sessionId: String?
    public let geoLocation: [String: Any]?
    public let locale: String?
    public let referrer: String?
    
    enum CodingKeys: String, CodingKey {
        case userAgent = "user_agent"
        case ipAddress = "ip_address"
        case frontendIp = "frontend_ip"
        case sessionId = "session_id"
        case geoLocation = "geo_location"
        case locale
        case referrer
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userAgent = try container.decodeIfPresent(String.self, forKey: .userAgent)
        ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
        frontendIp = try container.decodeIfPresent(String.self, forKey: .frontendIp)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        geoLocation = try container.decodeIfPresent([String: Any].self, forKey: .geoLocation)
        locale = try container.decodeIfPresent(String.self, forKey: .locale)
        referrer = try container.decodeIfPresent(String.self, forKey: .referrer)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userAgent, forKey: .userAgent)
        try container.encodeIfPresent(ipAddress, forKey: .ipAddress)
        try container.encodeIfPresent(frontendIp, forKey: .frontendIp)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(geoLocation, forKey: .geoLocation)
        try container.encodeIfPresent(locale, forKey: .locale)
        try container.encodeIfPresent(referrer, forKey: .referrer)
    }
}

// MARK: - Complete Verification Record

public struct OkIDVerificationRecord: Codable {
    public let id: String?
    public let verificationId: String
    public let createdAt: String
    public let config: OkIDVerificationConfig
    public let status: OkIDVerificationStatusInfo
    public let data: OkIDVerificationData
    public let timeline: [OkIDTimelineEvent]
    public let metadata: OkIDVerificationMetadata
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case verificationId = "verification_id"
        case createdAt = "created_at"
        case config
        case status
        case data
        case timeline
        case metadata
    }
}

// MARK: - Helper Extensions for Any Encoding/Decoding

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

extension KeyedEncodingContainerProtocol where Key == JSONCodingKeys {
    mutating func encode(_ value: [String: Any]) throws {
        for (key, value) in value {
            let key = JSONCodingKeys(stringValue: key)
            switch value {
            case let value as Bool:
                try encode(value, forKey: key)
            case let value as Int:
                try encode(value, forKey: key)
            case let value as String:
                try encode(value, forKey: key)
            case let value as Double:
                try encode(value, forKey: key)
            case let value as [String: Any]:
                var nestedContainer = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
                try nestedContainer.encode(value)
            case let value as [Any]:
                var nestedContainer = self.nestedUnkeyedContainer(forKey: key)
                try nestedContainer.encode(value)
            default:
                break
            }
        }
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [Any]) throws {
        for value in value {
            switch value {
            case let value as Bool:
                try encode(value)
            case let value as Int:
                try encode(value)
            case let value as String:
                try encode(value)
            case let value as Double:
                try encode(value)
            case let value as [String: Any]:
                var nestedContainer = self.nestedContainer(keyedBy: JSONCodingKeys.self)
                try nestedContainer.encode(value)
            case let value as [Any]:
                var nestedContainer = self.nestedUnkeyedContainer()
                try nestedContainer.encode(value)
            default:
                break
            }
        }
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encode(value)
    }
    
    mutating func encodeIfPresent(_ value: [String: Any]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        }
    }
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

