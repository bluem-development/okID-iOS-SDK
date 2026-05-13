import Foundation

/// Field detection status
enum MrzFieldStatus {
    case missing    // No valid detections
    case pending    // Detected but not yet validated (< 3 matches)
    case validated  // Validated (>= 3 matching detections)
}

/// MRZ field tracker for cross-frame confidence
/// Model class that accumulates OCR detections across video frames
/// and validates fields when enough consistent readings are gathered
class MrzTracker {
    private static let maxHistory = 5
    private static let minMatchesForConfidence = 3
    
    private var docNumberHistory: [String?] = []
    private var dobHistory: [String?] = []
    private var expiryHistory: [String?] = []
    
    // MARK: - Detection Input
    
    func addDetection(documentNumber: String?, dateOfBirth: String?, dateOfExpiry: String?) {
        addToHistory(&docNumberHistory, value: documentNumber)
        addToHistory(&dobHistory, value: dateOfBirth)
        addToHistory(&expiryHistory, value: dateOfExpiry)
    }
    
    private func addToHistory(_ history: inout [String?], value: String?) {
        history.append(value)
        if history.count > MrzTracker.maxHistory {
            history.removeFirst()
        }
    }
    
    // MARK: - Validated Values
    
    var validatedDocumentNumber: String? {
        return getMostCommonValue(docNumberHistory)
    }
    
    var validatedDateOfBirth: String? {
        return getMostCommonValue(dobHistory)
    }
    
    var validatedDateOfExpiry: String? {
        return getMostCommonValue(expiryHistory)
    }
    
    // MARK: - Field Statuses
    
    var documentNumberStatus: MrzFieldStatus {
        return getFieldStatus(docNumberHistory)
    }
    
    var dateOfBirthStatus: MrzFieldStatus {
        return getFieldStatus(dobHistory)
    }
    
    var dateOfExpiryStatus: MrzFieldStatus {
        return getFieldStatus(expiryHistory)
    }
    
    var allFieldsValidated: Bool {
        return validatedDocumentNumber != nil &&
               validatedDateOfBirth != nil &&
               validatedDateOfExpiry != nil
    }
    
    // MARK: - Debug
    
    var detectionCounts: [String: Int] {
        return [
            "documentNumber": docNumberHistory.compactMap { $0 }.count,
            "dateOfBirth": dobHistory.compactMap { $0 }.count,
            "dateOfExpiry": expiryHistory.compactMap { $0 }.count
        ]
    }
    
    // MARK: - Private Helpers
    
    private func getMostCommonValue(_ history: [String?]) -> String? {
        guard !history.isEmpty else { return nil }
        
        var counts: [String: Int] = [:]
        for value in history {
            if let val = value, !val.isEmpty {
                counts[val, default: 0] += 1
            }
        }
        
        guard !counts.isEmpty else { return nil }
        
        let mostCommon = counts.max(by: { $0.value < $1.value })
        
        if let (value, count) = mostCommon, count >= MrzTracker.minMatchesForConfidence {
            return value
        }
        
        return nil
    }
    
    private func getFieldStatus(_ history: [String?]) -> MrzFieldStatus {
        guard !history.isEmpty else { return .missing }
        
        if getMostCommonValue(history) != nil {
            return .validated
        }
        
        let hasAnyValue = history.contains(where: { $0 != nil && !$0!.isEmpty })
        return hasAnyValue ? .pending : .missing
    }
}
