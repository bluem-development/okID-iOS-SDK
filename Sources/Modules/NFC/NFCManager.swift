import Foundation

private let logger = Logger.nfc

// MARK: - NFC Manager

/// Manages business logic for the NFC module
/// Extracted from NFCInputViewController and MrzCameraViewController following MVC pattern
/// Handles: form validation, credential building, date parsing, MRZ parsing
class NFCManager {
    
    // MARK: - Form Validation
    
    /// Validate NFC input form fields
    func validateForm(
        documentNumber: String?,
        dateOfBirth: String?,
        dateOfExpiry: String?,
        can: String?
    ) -> Bool {
        let canText = can?.trimmingCharacters(in: .whitespaces) ?? ""
        let hasValidCAN = canText.count == 6
        
        // If CAN is provided, MRZ fields are optional
        if hasValidCAN { return true }
        
        // Otherwise, all MRZ fields required
        let docNumber = documentNumber?.trimmingCharacters(in: .whitespaces) ?? ""
        let dob = dateOfBirth?.trimmingCharacters(in: .whitespaces) ?? ""
        let expiry = dateOfExpiry?.trimmingCharacters(in: .whitespaces) ?? ""
        
        guard !docNumber.isEmpty else { return false }
        guard dob.count == 8 else { return false }
        guard expiry.count == 8 else { return false }
        guard isValidDateFormat(dob) else { return false }
        guard isValidDateFormat(expiry) else { return false }
        
        return true
    }
    
    /// Check if string matches DD.MM.YY format
    func isValidDateFormat(_ text: String) -> Bool {
        let pattern = "^\\d{2}\\.\\d{2}\\.\\d{2}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }
    
    // MARK: - Credential Building
    
    /// Build passport credentials from form field values
    func buildCredentials(
        documentNumber: String?,
        dateOfBirth: String?,
        dateOfExpiry: String?,
        can: String?
    ) throws -> OkIDPassportCredentials {
        let canText = can?.trimmingCharacters(in: .whitespaces) ?? ""
        let hasValidCAN = canText.count == 6
        
        let docNum: String
        let dob: Date
        let exp: Date
        
        if hasValidCAN && (documentNumber?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) {
            // CAN-only mode - use dummy values
            docNum = "CANONLY"
            dob = Date(timeIntervalSince1970: 631152000) // 1990-01-01
            exp = Date(timeIntervalSince1970: 1893456000) // 2030-01-01
        } else {
            // MRZ mode
            docNum = (documentNumber?.trimmingCharacters(in: .whitespaces) ?? "").uppercased()
            dob = try parseDDMMYY(dateOfBirth ?? "")
            exp = try parseDDMMYY(dateOfExpiry ?? "")
        }
        
        return OkIDPassportCredentials(
            documentNumber: docNum,
            dateOfBirth: dob,
            dateOfExpiry: exp,
            can: hasValidCAN ? canText : nil
        )
    }
    
    // MARK: - Date Helpers
    
    /// Format a Date to DD.MM.YY string
    func formatDateToDDMMYY(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        let dd = String(format: "%02d", components.day ?? 1)
        let mm = String(format: "%02d", components.month ?? 1)
        let yy = String(format: "%02d", (components.year ?? 2000) % 100)
        return "\(dd).\(mm).\(yy)"
    }
    
    /// Parse DD.MM.YY string to Date
    func parseDDMMYY(_ text: String) throws -> Date {
        let cleaned = text.replacingOccurrences(of: ".", with: "")
        
        guard cleaned.count == 6 else {
            throw NSError(domain: "InvalidDate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Date must be 6 digits"])
        }
        
        let ddIndex = cleaned.index(cleaned.startIndex, offsetBy: 2)
        let mmIndex = cleaned.index(cleaned.startIndex, offsetBy: 4)
        
        let dd = Int(cleaned[..<ddIndex]) ?? 0
        let mm = Int(cleaned[ddIndex..<mmIndex]) ?? 0
        let yy = Int(cleaned[mmIndex...]) ?? 0
        
        let year = yy >= 50 ? 1900 + yy : 2000 + yy
        
        var components = DateComponents()
        components.day = dd
        components.month = mm
        components.year = year
        
        guard let date = Calendar.current.date(from: components) else {
            throw NSError(domain: "InvalidDate", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid date components"])
        }
        
        return date
    }
    
    /// Parse YYMMDD string to Date
    func parseYYMMDD(_ yymmdd: String) -> Date? {
        guard yymmdd.count == 6,
              let yy = Int(yymmdd.prefix(2)),
              let mm = Int(yymmdd.dropFirst(2).prefix(2)),
              let dd = Int(yymmdd.dropFirst(4).prefix(2)) else {
            return nil
        }
        
        let year = yy >= 50 ? 1900 + yy : 2000 + yy
        let components = DateComponents(year: year, month: mm, day: dd)
        return Calendar.current.date(from: components)
    }
    
    /// Format raw digit input into DD.MM.YY with dots
    func formatDateInput(_ text: String) -> String {
        let digitsOnly = text.filter { $0.isNumber }
        let limited = String(digitsOnly.prefix(6))
        
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index == 2 || index == 4 {
                formatted += "."
            }
            formatted.append(char)
        }
        
        return formatted
    }
    
    // MARK: - MRZ Parsing
    
    /// Check if a line looks like passport MRZ line 1
    func isPassportMrzLine1(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else { return false }
        guard trimmed.hasPrefix("P") else { return false }
        guard trimmed.contains("<<") else { return false }
        return true
    }
    
    /// Check if a line looks like MRZ line 2
    func looksLikeMrzLine2(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let validPattern = "^[A-Z0-9<]+$"
        guard trimmed.range(of: validPattern, options: .regularExpression) != nil else {
            return false
        }
        guard trimmed.count >= 20 else { return false }
        guard trimmed.first?.isLetter == true || trimmed.first?.isNumber == true else {
            return false
        }
        
        return true
    }
    
    /// Parse MRZ line 2 to extract document fields
    func parseMrzLine2(_ line: String) -> [String: String?] {
        let cleaned = correctOcrErrors(line.uppercased())
        
        var result: [String: String?] = [:]
        
        if cleaned.count >= 10 {
            let docNum = String(cleaned.prefix(9))
                .replacingOccurrences(of: "<", with: "")
                .trimmingCharacters(in: .whitespaces)
            result["documentNumber"] = docNum.isEmpty ? nil : docNum
        }
        
        if cleaned.count >= 19 {
            let dobStr = String(cleaned.dropFirst(13).prefix(6))
            if dobStr.range(of: "^\\d{6}$", options: .regularExpression) != nil {
                result["dateOfBirth"] = dobStr
            } else {
                result["dateOfBirth"] = nil
            }
        }
        
        if cleaned.count >= 27 {
            let expStr = String(cleaned.dropFirst(21).prefix(6))
            if expStr.range(of: "^\\d{6}$", options: .regularExpression) != nil {
                result["dateOfExpiry"] = expStr
            } else {
                result["dateOfExpiry"] = nil
            }
        }
        
        return result
    }
    
    /// Correct common OCR mistakes in MRZ text
    func correctOcrErrors(_ text: String) -> String {
        var corrected = text
        corrected = corrected.replacingOccurrences(of: "O", with: "0")
        corrected = corrected.replacingOccurrences(of: "o", with: "0")
        corrected = corrected.replacingOccurrences(of: "I", with: "1")
        corrected = corrected.replacingOccurrences(of: "l", with: "1")
        corrected = corrected.replacingOccurrences(of: "Z", with: "2")
        corrected = corrected.replacingOccurrences(of: "S", with: "5")
        corrected = corrected.replacingOccurrences(of: "B", with: "8")
        return corrected
    }
    
    // MARK: - MRZ Status Message Building
    
    /// Build a user-facing status message from tracker field statuses
    func buildMrzStatusMessage(tracker: MrzTracker) -> String {
        if tracker.allFieldsValidated {
            return "All fields detected! Processing..."
        }
        
        let docStatus = tracker.documentNumberStatus
        let dobStatus = tracker.dateOfBirthStatus
        let expiryStatus = tracker.dateOfExpiryStatus
        
        var parts: [String] = []
        
        if docStatus == .validated {
            parts.append("✓ Doc Number")
        } else if docStatus == .pending {
            parts.append("⏳ Doc Number")
        }
        
        if dobStatus == .validated {
            parts.append("✓ DOB")
        } else if dobStatus == .pending {
            parts.append("⏳ DOB")
        }
        
        if expiryStatus == .validated {
            parts.append("✓ Expiry")
        } else if expiryStatus == .pending {
            parts.append("⏳ Expiry")
        }
        
        return parts.isEmpty ? "Align passport MRZ (bottom lines)" : parts.joined(separator: " | ")
    }
    
    // MARK: - MRZ Text Processing
    
    /// Process recognized text lines looking for MRZ patterns.
    /// Returns parsed fields added to the tracker, and whether all fields are now validated.
    func processRecognizedText(_ recognizedText: [String], tracker: MrzTracker) -> Bool {
        guard recognizedText.count >= 2 else { return false }
        
        var foundMrzPattern = false
        
        // Look for MRZ pattern: two consecutive lines
        for i in 0..<recognizedText.count - 1 {
            let line1 = recognizedText[i].uppercased()
            let line2 = recognizedText[i + 1].uppercased()
            
            if isPassportMrzLine1(line1) && looksLikeMrzLine2(line2) {
                foundMrzPattern = true
                
                let parsed = parseMrzLine2(line2)
                tracker.addDetection(
                    documentNumber: parsed["documentNumber"] ?? nil,
                    dateOfBirth: parsed["dateOfBirth"] ?? nil,
                    dateOfExpiry: parsed["dateOfExpiry"] ?? nil
                )
                
                if tracker.allFieldsValidated { return true }
                break
            }
        }
        
        // Fallback: try individual line 2 detection
        if !foundMrzPattern {
            for text in recognizedText {
                if looksLikeMrzLine2(text) {
                    let parsed = parseMrzLine2(text)
                    tracker.addDetection(
                        documentNumber: parsed["documentNumber"] ?? nil,
                        dateOfBirth: parsed["dateOfBirth"] ?? nil,
                        dateOfExpiry: parsed["dateOfExpiry"] ?? nil
                    )
                    
                    if tracker.allFieldsValidated { return true }
                    break
                }
            }
        }
        
        return false
    }
    
    /// Build OkIDPassportCredentials from validated tracker fields
    func buildCredentialsFromTracker(_ tracker: MrzTracker) -> OkIDPassportCredentials? {
        guard let docNum = tracker.validatedDocumentNumber,
              let dobStr = tracker.validatedDateOfBirth,
              let expStr = tracker.validatedDateOfExpiry else {
            return nil
        }
        
        guard let dob = parseYYMMDD(dobStr),
              let exp = parseYYMMDD(expStr) else {
            return nil
        }
        
        return OkIDPassportCredentials(
            documentNumber: docNum,
            dateOfBirth: dob,
            dateOfExpiry: exp,
            can: nil
        )
    }
}
