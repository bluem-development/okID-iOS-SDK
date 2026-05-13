import UIKit

/// Centralized color scheme for OkID Verification SDK
/// Provides consistent color palette across all SDK components
public extension UIColor {
    
    // MARK: - Brand Colors
    
    /// Primary brand color - Teal (#4ECDC4)
    static let okidPrimary = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1.0)
    
    /// Primary color with 80% opacity for borders and accents
    static let okidPrimaryBorder = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 0.8)
    
    /// Primary color with 10% opacity for subtle backgrounds
    static let okidPrimaryLight = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 0.1)
    
    /// Primary color with 30% opacity for borders
    static let okidPrimaryBorderLight = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 0.3)
    
    // MARK: - Semantic Colors
    
    /// Success color - Green (#10b981)
    static let okidSuccess = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
    
    /// Success color with 10% opacity for backgrounds
    static let okidSuccessLight = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.1)
    
    /// Success color with 30% opacity for borders
    static let okidSuccessBorder = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.3)
    
    /// Warning color - Amber (#f5a700)
    static let okidWarning = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
    
    /// Warning color - Yellow (#fbbf24)
    static let okidWarningYellow = UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0)
    
    /// Warning color with 10% opacity for backgrounds
    static let okidWarningLight = UIColor(red: 255/255, green: 193/255, blue: 7/255, alpha: 0.1)
    
    /// Warning color with 30% opacity for borders
    static let okidWarningBorder = UIColor(red: 255/255, green: 193/255, blue: 7/255, alpha: 0.3)
    
    /// Warning icon color - Orange (#ffa000)
    static let okidWarningIcon = UIColor(red: 255/255, green: 160/255, blue: 0/255, alpha: 1.0)
    
    /// Warning title color - Dark Orange (#ff8f00)
    static let okidWarningTitle = UIColor(red: 255/255, green: 143/255, blue: 0/255, alpha: 1.0)
    
    /// Error color - Red (#ef4444)
    static let okidError = UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0)
    
    /// Alternative error color - Darker Red (#f04444)
    static let okidErrorDark = UIColor(red: 0.94, green: 0.26, blue: 0.27, alpha: 1.0)
    
    // MARK: - Neutral Colors
    
    /// Gray - None state (#9ca3af)
    static let okidGrayNone = UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1.0)
    
    /// Gray 600 - Secondary text (#757575 / 117)
    static let okidGray600 = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1.0)
    
    /// Gray 500 - Tertiary text (#9e9e9e / 158)
    static let okidGray500 = UIColor(red: 158/255, green: 158/255, blue: 158/255, alpha: 1.0)
    
    /// Gray 400 - Borders (#787878 / 120)
    static let okidGray400 = UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1.0)
    
    /// Gray 200 - Light borders (#e5e5e5 / 0.9)
    static let okidGray200 = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    
    /// Secondary - Medium Gray (#6c757d)
    static let okidSecondary = UIColor(rgb: 0x6c757d)
    
    // MARK: - Text Colors
    
    /// Primary text color - Dark Gray (#1F2937)
    static let okidTextPrimary = UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1.0)
    
    /// Alternative primary text - Very Dark Gray (#1a1a1a)
    static let okidTextDark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    
    /// Secondary text color - Medium Gray (#757575)
    static let okidTextSecondary = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
    
    /// Tertiary text color - Light Gray (#9e9e9e)
    static let okidTextTertiary = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0)
    
    // MARK: - Background Colors
    
    /// Dark background - Navy (#0F172A)
    static let okidBackgroundDark = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1.0)
    
    /// Light background - Off-white (#F8F9FA / #f5f5f5)
    static let okidBackgroundLight = UIColor(rgb: 0xF8F9FA)
    
    /// Alternative light background (#f5f5f5)
    static let okidBackgroundLightAlt = UIColor(rgb: 0xf5f5f5)
    
    /// Lightest background (#f7f8f9)
    static let okidBackgroundLightest = UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0)
    
    /// Surface background - Very light gray (#f3f4f7)
    static let okidSurface = UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0)
    
    // MARK: - Border Colors
    
    /// Light border color (#e5e7eb)
    static let okidBorderLight = UIColor(rgb: 0xe5e7eb)
    
    /// Medium border color (#9e9e9e)
    static let okidBorderMedium = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    
    // MARK: - Button Colors
    
    /// Button background - Light gray (#f5f5f5)
    static let okidButtonLight = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
    
    /// Button text - Dark text (#1F2937)
    static let okidButtonText = UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1.0)
    
    // MARK: - Blue Accent Colors (for specific actions)
    
    /// Blue light background (#2196F3 @ 10%)
    static let okidBlueLight = UIColor(red: 33/255, green: 150/255, blue: 243/255, alpha: 0.1)
    
    /// Blue border (#2196F3 @ 30%)
    static let okidBlueBorder = UIColor(red: 33/255, green: 150/255, blue: 243/255, alpha: 0.3)
    
    /// Blue title - Medium blue (#1976D2)
    static let okidBlueTitle = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
    
    // MARK: - Helper Methods
    
    /// Create UIColor from hex value
    /// - Parameter rgb: Hex color value (e.g., 0x4ECDC4)
    /// - Returns: UIColor instance
    static func okidHex(_ rgb: UInt) -> UIColor {
        return UIColor(rgb: rgb)
    }
    
    /// Create UIColor with RGB values (0-255)
    /// - Parameters:
    ///   - r: Red component (0-255)
    ///   - g: Green component (0-255)
    ///   - b: Blue component (0-255)
    ///   - a: Alpha component (0.0-1.0)
    /// - Returns: UIColor instance
    static func okidRGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> UIColor {
        return UIColor(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}

// MARK: - OkID Color Scheme

/// Structured color scheme for OkID SDK
public struct OkIDColorScheme {
    
    // MARK: - Brand
    public struct Brand {
        public static let primary = UIColor.okidPrimary
        public static let primaryBorder = UIColor.okidPrimaryBorder
        public static let primaryLight = UIColor.okidPrimaryLight
        public static let primaryBorderLight = UIColor.okidPrimaryBorderLight
    }
    
    // MARK: - Semantic
    public struct Semantic {
        public static let success = UIColor.okidSuccess
        public static let successLight = UIColor.okidSuccessLight
        public static let successBorder = UIColor.okidSuccessBorder
        
        public static let warning = UIColor.okidWarning
        public static let warningYellow = UIColor.okidWarningYellow
        public static let warningLight = UIColor.okidWarningLight
        public static let warningBorder = UIColor.okidWarningBorder
        public static let warningIcon = UIColor.okidWarningIcon
        public static let warningTitle = UIColor.okidWarningTitle
        
        public static let error = UIColor.okidError
        public static let errorDark = UIColor.okidErrorDark
    }
    
    // MARK: - Neutral
    public struct Neutral {
        public static let grayNone = UIColor.okidGrayNone
        public static let gray600 = UIColor.okidGray600
        public static let gray500 = UIColor.okidGray500
        public static let gray400 = UIColor.okidGray400
        public static let gray200 = UIColor.okidGray200
        public static let secondary = UIColor.okidSecondary
    }
    
    // MARK: - Text
    public struct Text {
        public static let primary = UIColor.okidTextPrimary
        public static let dark = UIColor.okidTextDark
        public static let secondary = UIColor.okidTextSecondary
        public static let tertiary = UIColor.okidTextTertiary
    }
    
    // MARK: - Background
    public struct Background {
        public static let dark = UIColor.okidBackgroundDark
        public static let light = UIColor.okidBackgroundLight
        public static let lightAlt = UIColor.okidBackgroundLightAlt
        public static let lightest = UIColor.okidBackgroundLightest
        public static let surface = UIColor.okidSurface
    }
    
    // MARK: - Border
    public struct Border {
        public static let light = UIColor.okidBorderLight
        public static let medium = UIColor.okidBorderMedium
    }
    
    // MARK: - Button
    public struct Button {
        public static let light = UIColor.okidButtonLight
        public static let text = UIColor.okidButtonText
    }
    
    // MARK: - Blue Accent
    public struct Blue {
        public static let light = UIColor.okidBlueLight
        public static let border = UIColor.okidBlueBorder
        public static let title = UIColor.okidBlueTitle
    }
}
