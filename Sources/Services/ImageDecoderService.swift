import Foundation
import UIKit
import ImageIO

private let logger = Logger.document

/// Service for decoding JPEG2000 and other image formats
public class ImageDecoderService {
    
    public static let shared = ImageDecoderService()
    
    private init() {}
    
    /// Decode JPEG2000 image data to UIImage
    /// - Parameter jp2ImageData: Raw JPEG2000 data
    /// - Returns: Decoded UIImage or nil if decoding fails
    public func decodeJPEG2000(_ jp2ImageData: Data) -> UIImage? {
        // Try ImageIO first (supports JPEG2000 on iOS)
        if let cgImageSource = CGImageSourceCreateWithData(jp2ImageData as CFData, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
            return UIImage(cgImage: cgImage)
        }
        
        // Fallback: Check if it's actually regular JPEG
        if jp2ImageData.count >= 2 &&
           jp2ImageData[0] == 0xFF &&
           jp2ImageData[1] == 0xD8 {
            return UIImage(data: jp2ImageData)
        }
        
        logger.error("Failed to decode JPEG2000")
        return nil
    }
    
    /// Decode any image format supported by iOS
    /// - Parameter imageData: Raw image data
    /// - Returns: Decoded UIImage or nil
    public func decodeImage(_ imageData: Data) -> UIImage? {
        return UIImage(data: imageData)
    }
    
    /// Check if data is JPEG format
    /// - Parameter data: Image data
    /// - Returns: true if JPEG
    public func isJPEG(_ data: Data) -> Bool {
        return data.count >= 2 &&
            data[0] == 0xFF &&
            data[1] == 0xD8
    }
    
    /// Check if data is JPEG2000 format
    /// - Parameter data: Image data
    /// - Returns: true if JPEG2000
    public func isJPEG2000(_ data: Data) -> Bool {
        // JPEG2000 starts with 0x00 0x00 0x00 0x0C
        return data.count >= 12 &&
            data[0] == 0x00 &&
            data[1] == 0x00 &&
            data[2] == 0x00 &&
            data[3] == 0x0C
    }
    
    /// Convert any image format to JPEG
    /// - Parameters:
    ///   - imageData: Input image data
    ///   - quality: JPEG quality (0.0 to 1.0)
    /// - Returns: JPEG data or nil
    public func convertToJPEG(_ imageData: Data, quality: CGFloat = 0.9) -> Data? {
        guard let image = decodeImage(imageData) else { return nil }
        return image.jpegData(compressionQuality: quality)
    }
}

