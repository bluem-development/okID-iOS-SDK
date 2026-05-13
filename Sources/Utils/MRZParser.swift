import Foundation

private let logger = Logger.mrz

/// MRZ (Machine Readable Zone) parser for TD3 passport format
/// Extracts and validates document number, date of birth, and date of expiry
/// from MRZ line 2 using check digit validation
public class MRZParser {
    
    // MRZ check digit weights (7-3-1 pattern)
    private static let weights = [7, 3, 1]
    
    /// Correct common OCR errors in MRZ text
    public static func correctOCRErrors(_ text: String) -> String {
        // Common OCR mistakes in MRZ context
        let corrections: [Character: Character] = [
            "O": "0", "o": "0",
            "I": "1", "l": "1",
            "Z": "2",
            "S": "5",
            "B": "8",
            "G": "6",
            "e": "0",
            "D": "0"
        ]
        
        var corrected = text
        
        // Correct check digit positions (must be numeric)
        // Position 9 (doc number check), 19 (DOB check), 27 (expiry check)
        let checkPositions = [9, 19, 27]
        for pos in checkPositions {
            if pos < corrected.count {
                let index = corrected.index(corrected.startIndex, offsetBy: pos)
                let char = corrected[index]
                if let replacement = corrections[char] {
                    let range = index...index
                    corrected = corrected.replacingCharacters(in: range, with: String(replacement))
                    logger.debug("OCR correction at pos \(pos): \(char) -> \(replacement)")
                }
            }
        }
        
        // Correct date fields (positions 13-18 for DOB, 21-26 for expiry)
        let dateRanges = [[13, 19], [21, 27]]  // DOB and Expiry
        
        for range in dateRanges {
            let start = range[0]
            let end = range[1]
            
            if corrected.count >= end {
                for i in start..<end {
                    let index = corrected.index(corrected.startIndex, offsetBy: i)
                    let char = corrected[index]
                    if let replacement = corrections[char] {
                        corrected = corrected.replacingCharacters(in: index...index, with: String(replacement))
                        logger.debug("OCR correction in date at pos \(i): \(char) -> \(replacement)")
                    }
                }
            }
        }
        
        return corrected
    }
    
    /// Parse MRZ line 2 (TD3 format) and extract validated fields
    /// Returns a dictionary with keys: 'documentNumber', 'dateOfBirth', 'dateOfExpiry'
    /// Returns nil for invalid fields
    public static func parseLine2(_ line: String) -> [String: String?] {
        var cleanLine = line.trimmingCharacters(in: .whitespaces).uppercased()
        
        // Apply OCR error corrections
        cleanLine = correctOCRErrors(cleanLine)
        
        logger.debug("Line after corrections: \(cleanLine)")
        
        return [
            "documentNumber": parseDocumentNumber(cleanLine),
            "dateOfBirth": parseDateOfBirth(cleanLine),
            "dateOfExpiry": parseDateOfExpiry(cleanLine)
        ]
    }
    
    /// Extract and validate document number (positions 0-9)
    private static func parseDocumentNumber(_ line: String) -> String? {
        guard line.count >= 10 else { return nil }
        
        let dataEnd = line.index(line.startIndex, offsetBy: 9)
        let data = String(line[..<dataEnd])
        
        let checkIndex = line.index(line.startIndex, offsetBy: 9)
        guard let checkDigit = charToValue(line[checkIndex]) else {
            logger.debug("Doc number: Invalid check digit at position 9")
            return nil
        }
        
        let calculatedCheck = calculateCheckDigit(data)
        if calculatedCheck != checkDigit {
            logger.debug("Doc number check digit mismatch: expected \(calculatedCheck), got \(checkDigit) for \(data)")
            return nil
        }
        
        // Clean document number (replace < with space and trim)
        let cleaned = data.replacingOccurrences(of: "<", with: "").trimmingCharacters(in: .whitespaces)
        logger.debug("Doc number validated: \(cleaned)")
        return cleaned
    }
    
    /// Extract and validate date of birth (positions 13-19)
    private static func parseDateOfBirth(_ line: String) -> String? {
        guard line.count >= 20 else { return nil }
        
        let startPos = 13
        let endPos = min(19, line.count)
        
        guard endPos > startPos else { return nil }
        
        let startIndex = line.index(line.startIndex, offsetBy: startPos)
        let endIndex = line.index(line.startIndex, offsetBy: endPos)
        let data = String(line[startIndex..<endIndex])
        
        guard data.count >= 6 else { return nil }
        
        let dateStr = String(data.prefix(6))
        
        // Validate all digits
        guard dateStr.allSatisfy({ $0.isNumber }) else { return nil }
        
        // Check digit validation if available
        if line.count > 19 {
            let checkIndex = line.index(line.startIndex, offsetBy: 19)
            if let checkDigit = charToValue(line[checkIndex]) {
                let calculatedCheck = calculateCheckDigit(dateStr)
                if calculatedCheck != checkDigit {
                    logger.debug("DOB check digit mismatch: expected \(calculatedCheck), got \(checkDigit) for \(dateStr)")
                    return nil
                }
            }
        }
        
        logger.debug("DOB validated: \(dateStr)")
        return dateStr  // YYMMDD format
    }
    
    /// Extract and validate date of expiry (positions 21-27)
    private static func parseDateOfExpiry(_ line: String) -> String? {
        guard line.count >= 21 else { return nil }
        
        let startPos = 21
        let startIndex = line.index(line.startIndex, offsetBy: startPos)
        let data = String(line[startIndex...])
        
        // Try to extract 6 consecutive digits
        let regex = try! NSRegularExpression(pattern: "\\d{5,6}")
        let range = NSRange(data.startIndex..., in: data)
        
        guard let match = regex.firstMatch(in: data, range: range),
              let matchRange = Range(match.range, in: data) else {
            return nil
        }
        
        var dateStr = String(data[matchRange])
        
        guard dateStr.count >= 6 else { return nil }
        
        dateStr = String(dateStr.prefix(6))
        
        // Check digit validation if available
        let checkStartPos = startPos + 6
        if line.count > checkStartPos {
            let checkIndex = line.index(line.startIndex, offsetBy: checkStartPos)
            if let checkDigit = charToValue(line[checkIndex]) {
                let calculatedCheck = calculateCheckDigit(dateStr)
                if calculatedCheck != checkDigit {
                    logger.debug("Expiry check digit mismatch: expected \(calculatedCheck), got \(checkDigit) for \(dateStr)")
                    return nil
                }
            }
        }
        
        logger.debug("Expiry validated: \(dateStr)")
        return dateStr  // YYMMDD format
    }
    
    /// Calculate MRZ check digit using weighted sum algorithm
    private static func calculateCheckDigit(_ data: String) -> Int {
        var sum = 0
        
        for (i, char) in data.enumerated() {
            guard let charValue = charToValue(char) else { return -1 }
            
            let weight = weights[i % 3]
            sum += charValue * weight
        }
        
        return sum % 10
    }
    
    /// Convert MRZ character to its numeric value
    /// 0-9 -> 0-9, A-Z -> 10-35, < -> 0
    private static func charToValue(_ char: Character) -> Int? {
        let code = char.asciiValue ?? 0
        
        // 0-9
        if code >= 48 && code <= 57 {
            return Int(code - 48)
        }
        
        // A-Z
        if code >= 65 && code <= 90 {
            return Int(code - 55)  // A=10, B=11, ..., Z=35
        }
        
        // < (filler character)
        if char == "<" {
            return 0
        }
        
        return nil
    }
    
    /// Validates if a string is a TD3 passport MRZ line 1
    public static func isPassportMRZLine1(_ line: String) -> Bool {
        let cleanLine = line.uppercased().trimmingCharacters(in: .whitespaces)
        
        // TD3 line 1 is 44 chars (allow 38-48 for OCR variance)
        guard cleanLine.count >= 38 && cleanLine.count <= 48 else { return false }
        
        // Only valid MRZ characters: A-Z, 0-9, <
        let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "<"))
        guard cleanLine.unicodeScalars.allSatisfy({ validChars.contains($0) }) else { return false }
        
        // Must start with P (passport document type)
        guard cleanLine.hasPrefix("P") else { return false }
        
        // Must contain << (name separator)
        guard cleanLine.contains("<<") else { return false }
        
        // Country code at positions 2-4
        if cleanLine.count >= 5 {
            let start = cleanLine.index(cleanLine.startIndex, offsetBy: 2)
            let end = cleanLine.index(cleanLine.startIndex, offsetBy: 5)
            let countryCode = String(cleanLine[start..<end])
            
            let countryChars = CharacterSet.uppercaseLetters.union(CharacterSet(charactersIn: "<"))
            guard countryCode.unicodeScalars.allSatisfy({ countryChars.contains($0) }) else { return false }
            guard countryCode.contains(where: { $0.isLetter }) else { return false }
        }
        
        return true
    }
    
    /// Validate if a string looks like an MRZ line 2
    public static func looksLikeMRZLine2(_ line: String) -> Bool {
        let cleanLine = line.trimmingCharacters(in: .whitespaces).uppercased()
        
        // Only valid MRZ characters
        let validChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "<"))
        guard cleanLine.unicodeScalars.allSatisfy({ validChars.contains($0) }) else { return false }
        
        // Should be at least 20 characters
        guard cleanLine.count >= 20 else { return false }
        
        // Check if starts with alphanumeric
        guard cleanLine.first?.isLetter == true || cleanLine.first?.isNumber == true else { return false }
        
        // Check for 6 consecutive digits after position 10
        if cleanLine.count >= 19 {
            let start = cleanLine.index(cleanLine.startIndex, offsetBy: 10)
            let section = String(cleanLine[start...])
            
            let regex = try! NSRegularExpression(pattern: "\\d{6}")
            let range = NSRange(section.startIndex..., in: section)
            if regex.firstMatch(in: section, range: range) == nil {
                return false
            }
        }
        
        return true
    }
}

