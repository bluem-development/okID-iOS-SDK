import Foundation

// MARK: - Passport Credentials

public struct OkIDPassportCredentials {
    public let documentNumber: String
    public let dateOfBirth: Date
    public let dateOfExpiry: Date
    public let can: String?  // 6-digit Card Access Number for CAN-based PACE
    
    public init(
        documentNumber: String,
        dateOfBirth: Date,
        dateOfExpiry: Date,
        can: String? = nil
    ) {
        self.documentNumber = documentNumber
        self.dateOfBirth = dateOfBirth
        self.dateOfExpiry = dateOfExpiry
        self.can = can
    }
    
    /// Whether CAN is provided for CAN-based PACE
    public var hasCAN: Bool {
        return can != nil && can!.count == 6
    }
    
    /// Get date of birth in YYMMDD format
    public var dobFormatted: String {
        return formatDate(dateOfBirth)
    }
    
    /// Get date of expiry in YYMMDD format
    public var expiryFormatted: String {
        return formatDate(dateOfExpiry)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date) % 100
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return String(format: "%02d%02d%02d", year, month, day)
    }
    
    /// Validate credentials
    public func validate() -> Bool {
        return !documentNumber.isEmpty
    }
}

// MARK: - Personal Info

public struct OkIDPersonalInfo {
    public let documentType: String?
    public let issuingState: String?
    public let documentNumber: String?
    public let lastName: String?
    public let firstName: String?
    public let nationality: String?
    public let dateOfBirth: Date?
    public let gender: String?
    public let dateOfExpiry: Date?
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
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        dateOfExpiry: Date? = nil,
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

// MARK: - Passport Data

public struct OkIDPassportData {
    public let personalInfo: OkIDPersonalInfo?
    public let photo: Data?
    public let dataGroupsRead: [String]
    public let readAt: Date
    public let additionalInfo: [String: Any]?
    
    public init(
        personalInfo: OkIDPersonalInfo? = nil,
        photo: Data? = nil,
        dataGroupsRead: [String],
        readAt: Date,
        additionalInfo: [String: Any]? = nil
    ) {
        self.personalInfo = personalInfo
        self.photo = photo
        self.dataGroupsRead = dataGroupsRead
        self.readAt = readAt
        self.additionalInfo = additionalInfo
    }
}

// MARK: - NFC Read Error

public enum OkIDNFCReadError: Error, LocalizedError {
    case nfcNotSupported
    case tagConnectionLost
    case invalidCredentials
    case authenticationFailed
    case dataGroupNotFound(String)
    case invalidMRZ
    case unsupportedDocument
    case userCancelled
    case timeout
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .nfcNotSupported:
            return "NFC is not available on this device. Please use a physical iPhone with NFC capability and ensure NFC entitlements are configured."
        case .tagConnectionLost:
            return "Connection to passport lost. Please hold steady."
        case .invalidCredentials:
            return "Invalid passport credentials. Please check document number, date of birth, and expiry date."
        case .authenticationFailed:
            return "Authentication failed. Please verify your credentials."
        case .dataGroupNotFound(let group):
            return "Data group \(group) not found on passport."
        case .invalidMRZ:
            return "Could not read MRZ data from passport."
        case .unsupportedDocument:
            return "This document type is not supported for NFC reading."
        case .userCancelled:
            return "NFC reading was cancelled."
        case .timeout:
            return "NFC reading timed out. Please try again."
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - NFC Reading State

/// NFC reading state
public enum NFCReadingState {
    case idle
    case detecting
    case connecting
    case readingCardAccess
    case establishingSession
    case readingCOM
    case readingDataGroups
    case completed
    case error
}

/// NFC reading progress
public struct NFCReadingProgress {
    public let state: NFCReadingState
    public let message: String
    public let progress: Double  // 0.0 to 1.0
    public let error: String?
    
    public init(
        state: NFCReadingState,
        message: String,
        progress: Double,
        error: String? = nil
    ) {
        self.state = state
        self.message = message
        self.progress = progress
        self.error = error
    }
    
    public var isError: Bool { state == .error }
    public var isCompleted: Bool { state == .completed }
}

