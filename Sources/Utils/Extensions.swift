import Foundation
import UIKit
import ImageIO

// MARK: - UIColor Extensions

extension UIColor {
    /// Initialize color from hex value
   public convenience init(rgb: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    /// Convert to hex string
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06x", rgb)
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    /// Render the image with orientation applied so downstream Core ML code sees upright pixels.
    func normalizedUpImage() -> UIImage? {
        if imageOrientation == .up, let cgImage = cgImage {
            return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Crop a face region using a top-left based bounding box in image coordinates.
    func croppedFace(
        to boundingBox: CGRect,
        paddingXRatio: CGFloat = 0.20,
        paddingYRatio: CGFloat = 0.28
    ) -> UIImage? {
        guard let normalized = normalizedUpImage(),
              let cgImage = normalized.cgImage else {
            return nil
        }
        
        let imageRect = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let paddedRect = boundingBox.insetBy(
            dx: -boundingBox.width * paddingXRatio,
            dy: -boundingBox.height * paddingYRatio
        ).intersection(imageRect).integral
        
        guard paddedRect.width > 8,
              paddedRect.height > 8,
              let cropped = cgImage.cropping(to: paddedRect) else {
            return nil
        }
        
        return UIImage(cgImage: cropped, scale: 1.0, orientation: .up)
    }
    
    /// Resize image to max dimension using CoreGraphics (thread-safe)
    func resized(maxDimension: CGFloat) -> UIImage? {
        let scale = maxDimension / max(size.width, size.height)
        
        guard scale < 1.0 else { return self }
        guard let cgImage = self.cgImage else { return nil }
        
        let newWidth = Int(size.width * scale)
        let newHeight = Int(size.height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        guard let resizedCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: resizedCGImage, scale: 1.0, orientation: imageOrientation)
    }
    
    /// Convert to JPEG data with quality
    func jpegData(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
}

// MARK: - Data Extensions for Image Processing

extension Data {
    /// Get image pixel dimensions without decoding the full image
    /// Uses ImageIO metadata reading (very fast, no memory spike)
    func imagePixelSize() -> CGSize? {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options as CFDictionary) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        
        return CGSize(width: width, height: height)
    }
    
    /// Downsample image data efficiently using ImageIO
    /// This avoids decoding the full image into memory
    func downsampledUIImage(maxPixelSize: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        
        guard let source = CGImageSourceCreateWithData(self as CFData, options as CFDictionary) else {
            return nil
        }
        
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format as YYMMDD string
    func toYYMMDD() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return formatter.string(from: self)
    }
    
    /// Parse YYMMDD string
    static func fromYYMMDD(_ string: String) -> Date? {
        guard string.count == 6 else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return formatter.date(from: string)
    }
    
    /// Format as ISO date string (YYYY-MM-DD)
    func toISODateString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    /// SDK bundle
    static var sdkBundle: Bundle {
        Bundle(for: OkIDVerificationSDK.self)
    }
}

