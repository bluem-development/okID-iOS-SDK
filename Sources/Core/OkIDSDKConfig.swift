import Foundation
import UIKit

/// SDK Configuration
public struct OkIDSDKConfig {
    
    /// Backend API base URL
    public var baseUrl: String
    
    /// Connection timeout
    public let timeout: TimeInterval
    
    /// Number of retry attempts for failed requests
    public let retryAttempts: Int
    
    /// Theme configuration
    public let theme: OkIDThemeConfig
    
    /// Profile freshness threshold
    public let profileFreshnessThreshold: TimeInterval
    
    /// Enable debug logging (default: true for DEBUG builds, false for RELEASE)
    public var enableLogging: Bool
    
    /// BCP 47 language code sent with API requests (e.g. "en", "fr", "de").
    /// Defaults to the device's primary language.
    public let locale: String
    
    public init(
        baseUrl: String,
        timeout: TimeInterval = 30,
        retryAttempts: Int = 3,
        theme: OkIDThemeConfig = .defaultTheme,
        profileFreshnessThreshold: TimeInterval = 60 * 24 * 60 * 60, // 60 days
        enableLogging: Bool? = nil,
        locale: String? = nil
    ) {
        self.baseUrl = baseUrl
        self.timeout = timeout
        self.retryAttempts = retryAttempts
        self.theme = theme
        self.profileFreshnessThreshold = profileFreshnessThreshold
        self.locale = locale ?? Locale.current.languageCode ?? "en"
        
        // Default to DEBUG mode if not specified
        if let enableLogging = enableLogging {
            self.enableLogging = enableLogging
        } else {
            #if DEBUG
            self.enableLogging = true
            #else
            self.enableLogging = false
            #endif
        }
    }
}

// MARK: - Theme Configuration

public struct OkIDThemeConfig {
    public let colors: OkIDColorPalette
    public let typography: OkIDTypographyConfig
    public let spacing: OkIDSpacingConfig
    public let branding: OkIDBrandingConfig
    public let borderRadius: OkIDBorderRadiusConfig
    
    public init(
        colors: OkIDColorPalette,
        typography: OkIDTypographyConfig,
        spacing: OkIDSpacingConfig,
        branding: OkIDBrandingConfig,
        borderRadius: OkIDBorderRadiusConfig
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.branding = branding
        self.borderRadius = borderRadius
    }
    
    public static var defaultTheme: OkIDThemeConfig {
        OkIDThemeConfig(
            colors: .defaultPalette,
            typography: .defaultConfig,
            spacing: .defaultConfig,
            branding: .defaultConfig,
            borderRadius: .defaultConfig
        )
    }
}

// MARK: - Color Palette

public struct OkIDColorPalette {
    public let primary: UIColor
    public let secondary: UIColor
    public let accent: UIColor
    public let warning: UIColor
    public let error: UIColor
    public let background: UIColor
    public let surface: UIColor
    public let text: UIColor
    public let textSecondary: UIColor
    public let border: UIColor
    
    public init(
        primary: UIColor,
        secondary: UIColor,
        accent: UIColor,
        warning: UIColor,
        error: UIColor,
        background: UIColor,
        surface: UIColor,
        text: UIColor,
        textSecondary: UIColor,
        border: UIColor
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.warning = warning
        self.error = error
        self.background = background
        self.surface = surface
        self.text = text
        self.textSecondary = textSecondary
        self.border = border
    }
    
    public static var defaultPalette: OkIDColorPalette {
        OkIDColorPalette(
            primary: .okidPrimary,
            secondary: .okidSecondary,
            accent: .okidSuccess,
            warning: .okidWarningYellow,
            error: .okidError,
            background: .white,
            surface: .okidBackgroundLight,
            text: .okidTextDark,
            textSecondary: .okidSecondary,
            border: .okidBorderLight
        )
    }
}

// MARK: - Typography

public struct OkIDTypographyConfig {
    public let fontFamily: String
    public let fontSize: [String: CGFloat]
    public let fontWeight: [String: UIFont.Weight]
    
    public init(
        fontFamily: String,
        fontSize: [String: CGFloat],
        fontWeight: [String: UIFont.Weight]
    ) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
    
    public static var defaultConfig: OkIDTypographyConfig {
        OkIDTypographyConfig(
            fontFamily: "System",
            fontSize: [
                "xs": 12,
                "sm": 14,
                "base": 16,
                "lg": 18,
                "xl": 20,
                "2xl": 24,
                "3xl": 30
            ],
            fontWeight: [
                "normal": .regular,
                "medium": .medium,
                "semibold": .semibold,
                "bold": .bold
            ]
        )
    }
}

// MARK: - Spacing

public struct OkIDSpacingConfig {
    public let unit: CGFloat
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let xxl: CGFloat
    
    public init(
        unit: CGFloat,
        xs: CGFloat,
        sm: CGFloat,
        md: CGFloat,
        lg: CGFloat,
        xl: CGFloat,
        xxl: CGFloat
    ) {
        self.unit = unit
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }
    
    public static var defaultConfig: OkIDSpacingConfig {
        OkIDSpacingConfig(
            unit: 8,
            xs: 4,
            sm: 8,
            md: 16,
            lg: 24,
            xl: 32,
            xxl: 48
        )
    }
}

// MARK: - Branding

public struct OkIDBrandingConfig {
    public let organizationName: String
    public let logoImage: UIImage?
    public let primaryColor: UIColor
    public let secondaryColor: UIColor
    
    public init(
        organizationName: String,
        logoImage: UIImage? = nil,
        primaryColor: UIColor,
        secondaryColor: UIColor
    ) {
        self.organizationName = organizationName
        self.logoImage = logoImage
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    public static var defaultConfig: OkIDBrandingConfig {
        OkIDBrandingConfig(
            organizationName: "okID",
            primaryColor: .okidPrimary,
            secondaryColor: .okidSecondary
        )
    }
}

// MARK: - Border Radius

public struct OkIDBorderRadiusConfig {
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    
    public init(sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
    }
    
    public static var defaultConfig: OkIDBorderRadiusConfig {
        OkIDBorderRadiusConfig(sm: 6, md: 8, lg: 12, xl: 16)
    }
}

// MARK: - Verification Callbacks

public protocol OkIDVerificationCallbacks: AnyObject {
    func onModuleComplete(module: String, status: String)
    func onVerificationComplete(result: OkIDVerificationResult)
    func onError(error: String)
    func onCancel()
}

// MARK: - Verification Result

public struct OkIDVerificationResult {
    public let verificationId: String
    public let status: String
    public let data: [String: Any]?
    public let error: String?
    
    public var isSuccess: Bool { status == "verified" }
    public var isManualReview: Bool { status == "needs_manual_review" }
    public var isRejected: Bool { status == "rejected" }
    public var isExpired: Bool { status == "document_expired" }
    
    public init(verificationId: String, status: String, data: [String: Any]? = nil, error: String? = nil) {
        self.verificationId = verificationId
        self.status = status
        self.data = data
        self.error = error
    }
}

