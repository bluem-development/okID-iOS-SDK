# OkID Color Scheme

Centralized color palette for the OkID Verification SDK providing consistent styling across all components.

## Overview

The color scheme is organized into semantic categories for easy access and maintenance. Colors can be accessed through either:

1. **UIColor Extensions** - Direct color access via `UIColor.okid*` properties
2. **OkIDColorScheme Struct** - Organized by category for better discoverability

## Usage

### Direct Access (UIColor Extension)

```swift
view.backgroundColor = .okidPrimary
label.textColor = .okidTextPrimary
button.layer.borderColor = UIColor.okidBorderLight.cgColor
```

### Structured Access (OkIDColorScheme)

```swift
view.backgroundColor = OkIDColorScheme.Brand.primary
label.textColor = OkIDColorScheme.Text.primary
button.layer.borderColor = OkIDColorScheme.Border.light.cgColor
```

## Color Categories

### 1. Brand Colors

Primary brand identity colors:

```swift
.okidPrimary                    // Teal #4ECDC4 - Main brand color
.okidPrimaryBorder              // Teal @ 80% - For borders and accents
.okidPrimaryLight               // Teal @ 10% - Subtle backgrounds
.okidPrimaryBorderLight         // Teal @ 30% - Light borders
```

**Examples:**
```swift
// Primary button
button.backgroundColor = .okidPrimary

// Secondary button with border
button.backgroundColor = .okidPrimaryLight
button.layer.borderColor = UIColor.okidPrimaryBorderLight.cgColor
```

### 2. Semantic Colors

Colors that convey meaning:

#### Success (Green)

```swift
.okidSuccess                    // #10b981 - Success state
.okidSuccessLight               // Green @ 10% - Success background
.okidSuccessBorder              // Green @ 30% - Success border
```

**Example:**
```swift
// Success banner
banner.backgroundColor = .okidSuccess
label.textColor = .white
```

#### Warning (Amber/Yellow)

```swift
.okidWarning                    // #f5a700 - Warning state
.okidWarningYellow              // #fbbf24 - Alternative warning
.okidWarningLight               // Yellow @ 10% - Warning background
.okidWarningBorder              // Yellow @ 30% - Warning border
.okidWarningIcon                // #ffa000 - Warning icons
.okidWarningTitle               // #ff8f00 - Warning titles
```

**Example:**
```swift
// Warning message box
container.backgroundColor = .okidWarningLight
container.layer.borderColor = UIColor.okidWarningBorder.cgColor
iconView.tintColor = .okidWarningIcon
titleLabel.textColor = .okidWarningTitle
```

#### Error (Red)

```swift
.okidError                      // #ef4444 - Error state
.okidErrorDark                  // #f04444 - Alternative error
```

**Example:**
```swift
// Error message
label.textColor = .okidError
```

### 3. Neutral Colors

Gray scale for general UI elements:

```swift
.okidGrayNone                   // #9ca3af - None state indicator
.okidGray600                    // #757575 - Secondary text
.okidGray500                    // #9e9e9e - Tertiary text
.okidGray400                    // #787878 - Borders
.okidGray200                    // #e5e5e5 - Light borders
.okidSecondary                  // #6c757d - Secondary elements
```

**Example:**
```swift
// Form field
textField.layer.borderColor = UIColor.okidGray400.cgColor
placeholderLabel.textColor = .okidGray500
```

### 4. Text Colors

Typography colors:

```swift
.okidTextPrimary                // #1F2937 - Primary text
.okidTextDark                   // #1a1a1a - Very dark text
.okidTextSecondary              // #757575 - Secondary text
.okidTextTertiary               // #9e9e9e - Tertiary text
```

**Example:**
```swift
titleLabel.textColor = .okidTextPrimary
subtitleLabel.textColor = .okidTextSecondary
helperLabel.textColor = .okidTextTertiary
```

### 5. Background Colors

Surface and background colors:

```swift
.okidBackgroundDark             // #0F172A - Dark navy background
.okidBackgroundLight            // #F8F9FA - Light background
.okidBackgroundLightAlt         // #f5f5f5 - Alternative light
.okidBackgroundLightest         // #f7f8f9 - Lightest background
.okidSurface                    // #f3f4f7 - Surface background
```

**Example:**
```swift
view.backgroundColor = .okidBackgroundLight
card.backgroundColor = .white
navigationBar.backgroundColor = .okidBackgroundDark
```

### 6. Border Colors

Common border colors:

```swift
.okidBorderLight                // #e5e7eb - Light border
.okidBorderMedium               // #e5e5e5 - Medium border
```

**Example:**
```swift
cardView.layer.borderColor = UIColor.okidBorderLight.cgColor
cardView.layer.borderWidth = 1
```

### 7. Button Colors

Button-specific colors:

```swift
.okidButtonLight                // #f5f5f5 - Light button background
.okidButtonText                 // #1F2937 - Button text
```

**Example:**
```swift
button.backgroundColor = .okidButtonLight
button.setTitleColor(.okidButtonText, for: .normal)
```

### 8. Blue Accent Colors

Special blue colors for specific actions (e.g., MRZ scanning):

```swift
.okidBlueLight                  // #2196F3 @ 10% - Blue background
.okidBlueBorder                 // #2196F3 @ 30% - Blue border
.okidBlueTitle                  // #1976D2 - Blue title/text
```

**Example:**
```swift
// Scan MRZ button
button.backgroundColor = .okidBlueLight
button.layer.borderColor = UIColor.okidBlueBorder.cgColor
button.setTitleColor(.okidBlueTitle, for: .normal)
```

## Helper Methods

### Hex Color

```swift
let customColor = UIColor.okidHex(0x4ECDC4)
```

### RGB Color (0-255)

```swift
let customColor = UIColor.okidRGB(78, 205, 196)          // RGB
let customAlpha = UIColor.okidRGB(78, 205, 196, 0.5)     // RGB + Alpha
```

## Migration Guide

### Before (Hardcoded Colors)

```swift
// Old way
view.backgroundColor = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1.0)
label.textColor = UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1.0)
button.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
```

### After (Semantic Colors)

```swift
// New way - cleaner and semantic
view.backgroundColor = .okidPrimary
label.textColor = .okidTextPrimary
button.layer.borderColor = UIColor.okidGray200.cgColor
```

## Color Reference Table

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| `okidPrimary` | #4ECDC4 | 78, 205, 196 | Primary brand color |
| `okidSuccess` | #10b981 | 6, 185, 129 | Success states |
| `okidWarning` | #f5a700 | 245, 167, 0 | Warning states |
| `okidError` | #ef4444 | 239, 68, 68 | Error states |
| `okidTextPrimary` | #1F2937 | 31, 41, 55 | Primary text |
| `okidBackgroundDark` | #0F172A | 15, 23, 42 | Dark backgrounds |
| `okidBackgroundLight` | #F8F9FA | 248, 249, 250 | Light backgrounds |
| `okidGray600` | #757575 | 117, 117, 117 | Secondary text |

## Best Practices

1. **Use semantic names** over direct color values:
   ```swift
   // ✅ Good
   label.textColor = .okidTextSecondary
   
   // ❌ Avoid
   label.textColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
   ```

2. **Use appropriate opacity variants**:
   ```swift
   // ✅ Good - use predefined light variant
   container.backgroundColor = .okidPrimaryLight
   
   // ❌ Avoid - manual opacity
   container.backgroundColor = .okidPrimary.withAlphaComponent(0.1)
   ```

3. **Use structured access for better organization**:
   ```swift
   // ✅ Good - clear intent
   successIcon.tintColor = OkIDColorScheme.Semantic.success
   warningIcon.tintColor = OkIDColorScheme.Semantic.warning
   errorIcon.tintColor = OkIDColorScheme.Semantic.error
   ```

4. **For borders, always use CGColor**:
   ```swift
   // ✅ Correct
   layer.borderColor = UIColor.okidBorderLight.cgColor
   
   // ❌ Won't work
   layer.borderColor = UIColor.okidBorderLight
   ```

## Integration Example

```swift
import UIKit

class CustomViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Background
        view.backgroundColor = .okidBackgroundLight
        
        // Card container
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.okidBorderLight.cgColor
        
        // Title
        let titleLabel = OkIDLabel()
        titleLabel.text = "Welcome"
        titleLabel.textColor = .okidTextPrimary
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        
        // Subtitle
        let subtitleLabel = OkIDLabel()
        subtitleLabel.text = "Get started with verification"
        subtitleLabel.textColor = .okidTextSecondary
        subtitleLabel.font = .systemFont(ofSize: 16)
        
        // Primary button
        let primaryButton = UIButton()
        primaryButton.backgroundColor = .okidPrimary
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.setTitle("Continue", for: .normal)
        primaryButton.layer.cornerRadius = 12
        
        // Success badge
        let badge = UIView()
        badge.backgroundColor = .okidSuccessLight
        badge.layer.borderWidth = 1
        badge.layer.borderColor = UIColor.okidSuccessBorder.cgColor
        badge.layer.cornerRadius = 8
        
        let badgeLabel = OkIDLabel()
        badgeLabel.textColor = .okidSuccess
        badgeLabel.text = "Verified"
    }
}
```

## Notes

- All colors are compatible with iOS 13+
- Colors support both light and dark mode contexts
- Alpha values are pre-configured for common use cases
- Helper methods provide flexibility for custom colors when needed
