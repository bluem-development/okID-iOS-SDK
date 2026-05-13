import Foundation

// MARK: - Terms Module Config

public struct OkIDTermsModuleConfig: Codable {
    public let required: Bool
    public let version: String
    public let title: String
    public let content: String
    public let displaySummary: String?
    public let acceptanceRequired: Bool
    
    enum CodingKeys: String, CodingKey {
        case required
        case version
        case title
        case content
        case displaySummary = "display_summary"
        case acceptanceRequired = "acceptance_required"
    }
    
    public init(
        required: Bool,
        version: String,
        title: String,
        content: String,
        displaySummary: String? = nil,
        acceptanceRequired: Bool
    ) {
        self.required = required
        self.version = version
        self.title = title
        self.content = content
        self.displaySummary = displaySummary
        self.acceptanceRequired = acceptanceRequired
    }
}

// MARK: - Document Module Config

public struct OkIDDocumentModuleConfig: Codable {
    public let required: Bool
    public let acceptedDocuments: [String]
    public let qualityThreshold: Double
    public let allowFileUpload: Bool
    public let readNfcFromPassport: Bool
    public let requiresBackSide: Bool
    
    enum CodingKeys: String, CodingKey {
        case required
        case acceptedDocuments = "accepted_documents"
        case qualityThreshold = "quality_threshold"
        case allowFileUpload = "allow_file_upload"
        case readNfcFromPassport = "read_nfc_from_passport"
        case requiresBackSide = "requires_back_side"
    }
    
    public init(
        required: Bool,
        acceptedDocuments: [String],
        qualityThreshold: Double,
        allowFileUpload: Bool,
        readNfcFromPassport: Bool = false,
        requiresBackSide: Bool = true  // Changed default to true
    ) {
        self.required = required
        self.acceptedDocuments = acceptedDocuments
        self.qualityThreshold = qualityThreshold
        self.allowFileUpload = allowFileUpload
        self.readNfcFromPassport = readNfcFromPassport
        self.requiresBackSide = requiresBackSide
    }
}

// MARK: - Liveness Module Config

public struct OkIDLivenessModuleConfig: Codable {
    public let required: Bool
    public let mode: String?
    public let threshold: Double?
    public let maxAttempts: Int?
    
    enum CodingKeys: String, CodingKey {
        case required
        case mode
        case threshold
        case maxAttempts = "max_attempts"
    }
    
    public init(
        required: Bool,
        mode: String? = nil,
        threshold: Double? = nil,
        maxAttempts: Int? = nil
    ) {
        self.required = required
        self.mode = mode
        self.threshold = threshold
        self.maxAttempts = maxAttempts
    }
}

// MARK: - Form Field

public struct OkIDFormField: Codable {
    public let name: String
    public let type: String
    public let label: String
    public let required: Bool
    public let options: [String]?
    public let validation: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
            case name
            case type
            case label
            case required
            case options
            case validation
    }
    
    public init(
        name: String,
        type: String,
        label: String,
        required: Bool,
        options: [String]? = nil,
        validation: [String: Any]? = nil
    ) {
        self.name = name
        self.type = type
        self.label = label
        self.required = required
        self.options = options
        self.validation = validation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        label = try container.decode(String.self, forKey: .label)
        required = try container.decode(Bool.self, forKey: .required)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        
        if let validationDict = try? container.decode([String: AnyCodable].self, forKey: .validation) {
            validation = validationDict.mapValues { $0.value }
        } else {
            validation = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(label, forKey: .label)
        try container.encode(required, forKey: .required)
        try container.encodeIfPresent(options, forKey: .options)
        
        if let val = validation {
            let valDict = val.mapValues { AnyCodable($0) }
            try container.encode(valDict, forKey: .validation)
        }
    }
}

// MARK: - Form Data Module Config

public struct OkIDFormDataModuleConfig: Codable {
    public let required: Bool
    public let fields: [OkIDFormField]
    public let allowPartialSave: Bool
    
    enum CodingKeys: String, CodingKey {
        case required
        case fields
        case allowPartialSave = "allow_partial_save"
    }
    
    public init(
        required: Bool,
        fields: [OkIDFormField],
        allowPartialSave: Bool
    ) {
        self.required = required
        self.fields = fields
        self.allowPartialSave = allowPartialSave
    }
}

