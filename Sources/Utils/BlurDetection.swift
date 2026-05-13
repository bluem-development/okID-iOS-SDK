import Foundation
import UIKit
import CoreGraphics

/// Blur detection using Sobel edge detection (matching the reference implementation)
public class BlurDetection {
    
    /// Detection square size (sample center only, not full image)
    /// Must match v2client BLUR_DETECTION_SQUARE_SIZE constant
    public static let detectionSquareSize: Int = 512
    
    /// Quality threshold for documents
    public static let qualityThreshold: Double = 6.0
    
    /// Calculate blur score using Sobel edge detection
    /// Matches the reference implementation exactly
    ///
    /// Higher score = sharper image
    /// Typical thresholds: 5-10 for documents
    public static func calculateBlurScore(image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Sample center square only (like v2client)
        let squareSize = min(detectionSquareSize, min(width, height))
        let startX = max(0, (width - squareSize) / 2)
        let startY = max(0, (height - squareSize) / 2)
        let endX = min(width, startX + squareSize)
        let endY = min(height, startY + squareSize)
        
        let samplingWidth = endX - startX
        let samplingHeight = endY - startY
        
        guard samplingWidth > 0 && samplingHeight > 0 else {
            return 0
        }
        
        // Convert to grayscale pixel data
        guard let pixelData = extractGrayscalePixels(from: cgImage, 
                                                      startX: startX, 
                                                      startY: startY, 
                                                      width: samplingWidth, 
                                                      height: samplingHeight) else {
            return 0
        }
        
        // Apply Sobel edge detection
        return calculateSobelBlurriness(pixelData: pixelData, 
                                       width: samplingWidth, 
                                       height: samplingHeight)
    }
    
    /// Extract grayscale pixel data from image region
    /// Optimized: crops to the target region FIRST, then converts to grayscale
    /// This dramatically reduces memory usage for large images
    private static func extractGrayscalePixels(from cgImage: CGImage, 
                                              startX: Int, 
                                              startY: Int, 
                                              width: Int, 
                                              height: Int) -> [UInt8]? {
        // First, crop to the target region (CGImage.cropping is very efficient)
        let cropRect = CGRect(x: startX, y: startY, width: width, height: height)
        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        let croppedWidth = croppedImage.width
        let croppedHeight = croppedImage.height
        
        // Create grayscale context ONLY for the cropped region (not the full image)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: croppedWidth,
            height: croppedHeight,
            bitsPerComponent: 8,
            bytesPerRow: croppedWidth,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        context.draw(croppedImage, in: CGRect(x: 0, y: 0, width: croppedWidth, height: croppedHeight))
        
        guard let data = context.data else { return nil }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        
        // Copy to array
        var regionData = [UInt8](repeating: 0, count: croppedWidth * croppedHeight)
        for i in 0..<(croppedWidth * croppedHeight) {
            regionData[i] = pixelData[i]
        }
        
        return regionData
    }
    
    /// Calculate blurriness using Sobel edge detection
    private static func calculateSobelBlurriness(pixelData: [UInt8], 
                                                 width: Int, 
                                                 height: Int) -> Double {
        // Sobel kernels
        let sobelX: [Double] = [-1, 0, 1, -2, 0, 2, -1, 0, 1]
        let sobelY: [Double] = [-1, -2, -1, 0, 0, 0, 1, 2, 1]
        
        var sum: Double = 0.0
        var count: Int = 0
        
        // Apply Sobel to each pixel (excluding borders)
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var gx: Double = 0.0
                var gy: Double = 0.0
                
                for ky in -1...1 {
                    for kx in -1...1 {
                        let pixelY = y + ky
                        let pixelX = x + kx
                        let pixelIndex = pixelY * width + pixelX
                        let gray = Double(pixelData[pixelIndex])
                        let kernelIdx = (ky + 1) * 3 + (kx + 1)
                        
                        gx += gray * sobelX[kernelIdx]
                        gy += gray * sobelY[kernelIdx]
                    }
                }
                
                // Calculate gradient magnitude
                let magnitude = sqrt(gx * gx + gy * gy)
                sum += magnitude
                count += 1
            }
        }
        
        let averageMagnitude = count > 0 ? sum / Double(count) : 0.0
        
        // Normalize to match v2client (empirically determined factor)
        return averageMagnitude * 0.2
    }
    
    /// Get blur quality description
    public static func getQualityDescription(blurScore: Double) -> String {
        if blurScore < 4 {
            return "Very Blurry"
        } else if blurScore < 6 {
            return "Slightly Blurry"
        } else if blurScore < 10 {
            return "Good"
        } else {
            return "Excellent"
        }
    }
    
    /// Check if image meets quality threshold
    public static func meetsQualityThreshold(image: UIImage, threshold: Double = qualityThreshold) -> Bool {
        let score = calculateBlurScore(image: image)
        return score >= threshold
    }
    
    /// Check if blur score meets quality threshold
    public static func meetsQualityThreshold(blurScore: Double, threshold: Double = qualityThreshold) -> Bool {
        return blurScore >= threshold
    }
}
