import Foundation

// MARK: - Profile Module Status

public enum OkIDProfileModuleStatus {
    case none
    case fresh
    case outdated
}

// MARK: - Profile Status

public struct OkIDProfileStatus {
    public let document: OkIDProfileModuleStatus
    public let liveness: OkIDProfileModuleStatus
    public let nfc: OkIDProfileModuleStatus
    public let documentCapturedAt: Int64?
    public let livenessCapturedAt: Int64?
    public let nfcCapturedAt: Int64?
    
    public init(
        document: OkIDProfileModuleStatus = .none,
        liveness: OkIDProfileModuleStatus = .none,
        nfc: OkIDProfileModuleStatus = .none,
        documentCapturedAt: Int64? = nil,
        livenessCapturedAt: Int64? = nil,
        nfcCapturedAt: Int64? = nil
    ) {
        self.document = document
        self.liveness = liveness
        self.nfc = nfc
        self.documentCapturedAt = documentCapturedAt
        self.livenessCapturedAt = livenessCapturedAt
        self.nfcCapturedAt = nfcCapturedAt
    }
    
    public var hasAnyFreshData: Bool {
        document == .fresh || liveness == .fresh || nfc == .fresh
    }
    
    public var isComplete: Bool {
        document == .fresh && liveness == .fresh
    }
    
    public var freshCount: Int {
        var count = 0
        if document == .fresh { count += 1 }
        if liveness == .fresh { count += 1 }
        if nfc == .fresh { count += 1 }
        return count
    }
    
    public static let empty = OkIDProfileStatus()
}

// MARK: - Profile Document Data

public struct OkIDProfileDocumentData: Codable {
    public let frontImage: Data
    public let backImage: Data?
    public let capturedAt: Int64
    
    public init(frontImage: Data, backImage: Data? = nil, capturedAt: Int64) {
        self.frontImage = frontImage
        self.backImage = backImage
        self.capturedAt = capturedAt
    }
}

// MARK: - Profile Liveness Data

public struct OkIDProfileLivenessData: Codable {
    public let selfieImage: Data
    public let capturedAt: Int64
    public let estimatedAge: Double?
    public let estimatedGender: String?
    public let genderConfidence: Double?
    
    public init(
        selfieImage: Data,
        capturedAt: Int64,
        estimatedAge: Double? = nil,
        estimatedGender: String? = nil,
        genderConfidence: Double? = nil
    ) {
        self.selfieImage = selfieImage
        self.capturedAt = capturedAt
        self.estimatedAge = estimatedAge
        self.estimatedGender = estimatedGender
        self.genderConfidence = genderConfidence
    }
}

// MARK: - Profile Passport Info

public struct OkIDProfilePassportInfo: Codable {
    public let documentType: String?
    public let issuingState: String?
    public let documentNumber: String?
    public let lastName: String?
    public let firstName: String?
    public let nationality: String?
    public let dateOfBirth: String?
    public let gender: String?
    public let dateOfExpiry: String?
    public let optionalData1: String?
    public let optionalData2: String?
    
    public var fullName: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
    
    public init(
        documentType: String? = nil,
        issuingState: String? = nil,
        documentNumber: String? = nil,
        lastName: String? = nil,
        firstName: String? = nil,
        nationality: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        dateOfExpiry: String? = nil,
        optionalData1: String? = nil,
        optionalData2: String? = nil
    ) {
        self.documentType = documentType
        self.issuingState = issuingState
        self.documentNumber = documentNumber
        self.lastName = lastName
        self.firstName = firstName
        self.nationality = nationality
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.dateOfExpiry = dateOfExpiry
        self.optionalData1 = optionalData1
        self.optionalData2 = optionalData2
    }
}

// MARK: - Profile NFC Data

public struct OkIDProfileNfcData: Codable {
    public let personalInfo: OkIDProfilePassportInfo
    public let photo: Data?
    public let dataGroupsRead: [String]
    public let capturedAt: Int64
    
    public init(
        personalInfo: OkIDProfilePassportInfo,
        photo: Data? = nil,
        dataGroupsRead: [String],
        capturedAt: Int64
    ) {
        self.personalInfo = personalInfo
        self.photo = photo
        self.dataGroupsRead = dataGroupsRead
        self.capturedAt = capturedAt
    }
}

// MARK: - Verification Profile

public struct OkIDVerificationProfile: Codable {
    public static let currentVersion = 1
    
    public let version: Int
    public let document: OkIDProfileDocumentData?
    public let liveness: OkIDProfileLivenessData?
    public let nfc: OkIDProfileNfcData?
    public let createdAt: Int64
    public let updatedAt: Int64
    
    public var isEmpty: Bool {
        document == nil && liveness == nil && nfc == nil
    }
    
    public init(
        version: Int = currentVersion,
        document: OkIDProfileDocumentData? = nil,
        liveness: OkIDProfileLivenessData? = nil,
        nfc: OkIDProfileNfcData? = nil,
        createdAt: Int64? = nil,
        updatedAt: Int64? = nil
    ) {
        self.version = version
        self.document = document
        self.liveness = liveness
        self.nfc = nfc
        
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }
    
    public func getModuleStatus(module: String, freshnessThreshold: TimeInterval) -> OkIDProfileModuleStatus {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let thresholdMs = Int64(freshnessThreshold * 1000)
        
        switch module {
        case "document":
            guard let doc = document else { return .none }
            return (now - doc.capturedAt) < thresholdMs ? .fresh : .outdated
        case "liveness":
            guard let live = liveness else { return .none }
            return (now - live.capturedAt) < thresholdMs ? .fresh : .outdated
        case "nfc":
            guard let nfcData = nfc else { return .none }
            return (now - nfcData.capturedAt) < thresholdMs ? .fresh : .outdated
        default:
            return .none
        }
    }
    
    public func getStatus(freshnessThreshold: TimeInterval) -> OkIDProfileStatus {
        OkIDProfileStatus(
            document: getModuleStatus(module: "document", freshnessThreshold: freshnessThreshold),
            liveness: getModuleStatus(module: "liveness", freshnessThreshold: freshnessThreshold),
            nfc: getModuleStatus(module: "nfc", freshnessThreshold: freshnessThreshold),
            documentCapturedAt: document?.capturedAt,
            livenessCapturedAt: liveness?.capturedAt,
            nfcCapturedAt: nfc?.capturedAt
        )
    }
    
    public func copyWith(
        document: OkIDProfileDocumentData? = nil,
        liveness: OkIDProfileLivenessData? = nil,
        nfc: OkIDProfileNfcData? = nil,
        clearDocument: Bool = false,
        clearLiveness: Bool = false,
        clearNfc: Bool = false
    ) -> OkIDVerificationProfile {
        OkIDVerificationProfile(
            version: version,
            document: clearDocument ? nil : (document ?? self.document),
            liveness: clearLiveness ? nil : (liveness ?? self.liveness),
            nfc: clearNfc ? nil : (nfc ?? self.nfc),
            createdAt: createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}

// MARK: - Profile Result

public struct OkIDProfileResult {
    public let success: Bool
    public let status: OkIDProfileStatus?
    public let error: String?
    public let modified: Bool
    
    public init(success: Bool, status: OkIDProfileStatus? = nil, error: String? = nil, modified: Bool = false) {
        self.success = success
        self.status = status
        self.error = error
        self.modified = modified
    }
    
    public static func success(status: OkIDProfileStatus? = nil, modified: Bool = false) -> OkIDProfileResult {
        OkIDProfileResult(success: true, status: status, modified: modified)
    }
    
    public static func failure(_ error: String) -> OkIDProfileResult {
        OkIDProfileResult(success: false, error: error)
    }
    
    public static func cancelled() -> OkIDProfileResult {
        OkIDProfileResult(success: true, modified: false)
    }
}

