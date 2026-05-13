import Foundation

private let logger = Logger.nfc

/// Parser for DG2 ISO 19794-5 biometric data format
public class DG2Parser {
    private let data: Data
    private var offset: Int = 0
    
    public init(data: Data) {
        self.data = data
    }
    
    /// Extract facial image data from DG2
    public func extractImageData() -> Data? {
        do {
            // Skip outer wrapper tag (0x75 or similar)
            var tag = try getNextTag()
            logger.debug("First tag: 0x\(String(format: "%02X", tag))")
            _ = try getNextLength()
            
            // Look for tag 0x7F61 - Biometric Information Template
            tag = try getNextTag()
            if tag != 0x7F61 {
                logger.debug("Expected tag 0x7F61, got 0x\(String(format: "%02X", tag))")
                return nil
            }
            _ = try getNextLength()
            
            // Tag 0x02 - Number of instances
            tag = try getNextTag()
            if tag != 0x02 {
                logger.debug("Expected tag 0x02, got 0x\(String(format: "%02X", tag))")
                return nil
            }
            let nrImages = try getNextValue()[0]
            
            // Tag 0x7F60 - Biometric Information Group Template
            tag = try getNextTag()
            if tag != 0x7F60 {
                logger.debug("Expected tag 0x7F60, got 0x\(String(format: "%02X", tag))")
                return nil
            }
            _ = try getNextLength()
            
            // Tag 0xA1 - Biometric Header Template (skip it)
            tag = try getNextTag()
            if tag == 0xA1 {
                _ = try getNextValue()
            }
            
            // Tag 0x5F2E or 0x7F2E - Biometric data block
            tag = try getNextTag()
            if tag != 0x5F2E && tag != 0x7F2E {
                logger.debug("Expected tag 0x5F2E or 0x7F2E, got 0x\(String(format: "%02X", tag))")
                return nil
            }
            let bioData = try getNextValue()
            
            // Parse ISO 19794-5 format
            return parseISO19794_5(Data(bioData))
            
        } catch {
            logger.error("Error: \(error)")
            return nil
        }
    }
    
    private func getNextTag() throws -> Int {
        guard offset < data.count else {
            throw DG2ParserError.offsetOutOfBounds
        }
        
        var tag = Int(data[offset])
        offset += 1
        
        // Check if it's a multi-byte tag
        if (tag & 0x1F) == 0x1F {
            guard offset < data.count else {
                throw DG2ParserError.offsetOutOfBounds
            }
            tag = (tag << 8) | Int(data[offset])
            offset += 1
        }
        
        return tag
    }
    
    private func getNextLength() throws -> Int {
        guard offset < data.count else {
            throw DG2ParserError.offsetOutOfBounds
        }
        
        var length = Int(data[offset])
        offset += 1
        
        if (length & 0x80) != 0 {
            // Long form
            let numBytes = length & 0x7F
            length = 0
            for _ in 0..<numBytes {
                guard offset < data.count else {
                    throw DG2ParserError.offsetOutOfBounds
                }
                length = (length << 8) | Int(data[offset])
                offset += 1
            }
        }
        
        return length
    }
    
    private func getNextValue() throws -> [UInt8] {
        let length = try getNextLength()
        guard offset + length <= data.count else {
            throw DG2ParserError.offsetOutOfBounds
        }
        
        let value = Array(data[offset..<offset + length])
        offset += length
        return value
    }
    
    private func parseISO19794_5(_ bioData: Data) -> Data? {
        var off = 4  // Skip format identifier
        
        guard bioData.count > off + 30 else { return nil }
        
        off += 4  // version
        off += 4  // length of record
        off += 2  // number of facial images
        off += 4  // facial record data length
        
        let nrFeaturePoints = binToInt(Array(bioData[off..<off + 2]))
        off += 2
        
        off += 1  // gender
        off += 1  // eye color
        off += 1  // hair color
        off += 3  // feature mask
        off += 2  // expression
        off += 3  // pose angle
        off += 3  // pose angle uncertainty
        
        // Skip feature points
        off += nrFeaturePoints * 8
        
        off += 1  // face image type
        off += 1  // image data type
        off += 2  // width
        off += 2  // height
        off += 1  // color space
        off += 1  // source type
        off += 2  // device type
        off += 2  // quality
        
        // Rest is image data
        guard off < bioData.count else { return nil }
        return bioData[off...]
    }
    
    private func binToInt(_ bytes: [UInt8]) -> Int {
        return bytes.reduce(0) { ($0 << 8) + Int($1) }
    }
}

enum DG2ParserError: Error {
    case offsetOutOfBounds
    case invalidFormat
}

