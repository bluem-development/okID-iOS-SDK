import Foundation

/// Status of MRZ field detection
public enum MRZFieldStatus {
    case missing    // No valid detections
    case pending    // Detected but not yet validated (< 3 matches)
    case validated  // Validated (>= 3 matching detections)
}

/// MRZ field detection tracker for cross-frame confidence
/// Tracks detection results across multiple frames and returns validated
/// values only when there's sufficient confidence (3+ matching detections)
public class MRZTracker {
    
    private static let maxHistory = 5
    private static let minMatchesForConfidence = 3
    
    private var docNumberHistory: [String?] = []
    private var dobHistory: [String?] = []
    private var expiryHistory: [String?] = []
    
    public init() {}
    
    /// Add detection result from a frame
    public func addDetection(
        documentNumber: String?,
        dateOfBirth: String?,
        dateOfExpiry: String?
    ) {
        addToHistory(&docNumberHistory, value: documentNumber)
        addToHistory(&dobHistory, value: dateOfBirth)
        addToHistory(&expiryHistory, value: dateOfExpiry)
    }
    
    /// Add value to history, maintaining max size
    private func addToHistory(_ history: inout [String?], value: String?) {
        history.append(value)
        if history.count > Self.maxHistory {
            history.removeFirst()
        }
    }
    
    /// Get validated document number if confidence threshold met
    public var validatedDocumentNumber: String? {
        return getMostCommonValue(docNumberHistory)
    }
    
    /// Get validated date of birth if confidence threshold met
    public var validatedDateOfBirth: String? {
        return getMostCommonValue(dobHistory)
    }
    
    /// Get validated date of expiry if confidence threshold met
    public var validatedDateOfExpiry: String? {
        return getMostCommonValue(expiryHistory)
    }
    
    /// Get detection status for document number
    public var documentNumberStatus: MRZFieldStatus {
        return getFieldStatus(docNumberHistory)
    }
    
    /// Get detection status for date of birth
    public var dateOfBirthStatus: MRZFieldStatus {
        return getFieldStatus(dobHistory)
    }
    
    /// Get detection status for date of expiry
    public var dateOfExpiryStatus: MRZFieldStatus {
        return getFieldStatus(expiryHistory)
    }
    
    /// Check if all fields are validated
    public var allFieldsValidated: Bool {
        return validatedDocumentNumber != nil &&
            validatedDateOfBirth != nil &&
            validatedDateOfExpiry != nil
    }
    
    /// Get most common non-null value if it appears enough times
    private func getMostCommonValue(_ history: [String?]) -> String? {
        guard !history.isEmpty else { return nil }
        
        // Count occurrences of each value
        var counts: [String: Int] = [:]
        for value in history {
            if let value = value, !value.isEmpty {
                counts[value, default: 0] += 1
            }
        }
        
        guard !counts.isEmpty else { return nil }
        
        // Find most common value
        var mostCommon: String?
        var maxCount = 0
        
        for (value, count) in counts {
            if count > maxCount {
                maxCount = count
                mostCommon = value
            }
        }
        
        // Return only if meets confidence threshold
        if maxCount >= Self.minMatchesForConfidence {
            return mostCommon
        }
        
        return nil
    }
    
    /// Get field detection status
    private func getFieldStatus(_ history: [String?]) -> MRZFieldStatus {
        guard !history.isEmpty else { return .missing }
        
        if getMostCommonValue(history) != nil {
            return .validated
        }
        
        // Check if we have any non-null values (pending validation)
        let hasAnyValue = history.contains { value in
            if let value = value, !value.isEmpty {
                return true
            }
            return false
        }
        
        return hasAnyValue ? .pending : .missing
    }
    
    /// Reset all tracking data
    public func reset() {
        docNumberHistory.removeAll()
        dobHistory.removeAll()
        expiryHistory.removeAll()
    }
    
    /// Get current detection counts for debugging
    public var detectionCounts: [String: Int] {
        return [
            "documentNumber": docNumberHistory.compactMap { $0 }.count,
            "dateOfBirth": dobHistory.compactMap { $0 }.count,
            "dateOfExpiry": expiryHistory.compactMap { $0 }.count
        ]
    }
}

