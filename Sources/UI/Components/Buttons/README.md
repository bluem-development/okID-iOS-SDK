# OkID Button Components

Custom button components for consistent UI throughout the OkID Verification SDK.

## Components

### 1. OkIDButton (Base Class)

Base button class with common functionality including:
- Loading states with activity indicator
- Touch effects (scale and fade)
- Configurable appearance
- Icon support with flexible placement

**Usage:**
```swift
let button = OkIDButton(config: .primary())
button.setTitle("My Button", for: .normal)
button.isLoading = true // Show loading state
```

### 2. OkIDPrimaryButton

For main actions with solid background and shadow effect.

**Usage:**
```swift
let button = OkIDPrimaryButton(
    title: "Start Verification",
    icon: UIImage(systemName: "checkmark.shield")
)
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

// Change color
button.setColor(.systemBlue)

// Show loading
button.isLoading = true
```

**Features:**
- Solid colored background
- Prominent shadow
- Default teal color (#4ECDC4)
- White text
- Optional icon

### 3. OkIDSecondaryButton

For less prominent actions with outlined style.

**Usage:**
```swift
let button = OkIDSecondaryButton(
    title: "Scan QR Code",
    icon: UIImage(systemName: "qrcode.viewfinder")
)

// Custom border color
let customButton = OkIDSecondaryButton(
    title: "Settings",
    borderColor: .systemGray,
    icon: UIImage(systemName: "gearshape")
)
```

**Features:**
- Transparent background with slight tint
- Border outline
- No shadow
- White text by default
- Optional icon

### 4. OkIDTertiaryButton

For minimal UI presence (text-only style).

**Usage:**
```swift
let button = OkIDTertiaryButton(
    title: "Cancel",
    titleColor: .systemRed
)

// With icon
let linkButton = OkIDTertiaryButton(
    title: "Learn More",
    icon: UIImage(systemName: "arrow.right")
)
```

**Features:**
- No background
- No border
- No shadow
- Flexible height
- Ideal for inline links or cancel actions

## Configuration

### OkIDButtonConfig

Create custom button configurations:

```swift
let customConfig = OkIDButtonConfig(
    backgroundColor: .systemPurple,
    titleColor: .white,
    font: UIFont.systemFont(ofSize: 18, weight: .bold),
    cornerRadius: 12,
    borderWidth: 2,
    borderColor: .white,
    hasShadow: true,
    icon: UIImage(systemName: "star.fill"),
    iconPlacement: .trailing,
    height: 60
)

let button = OkIDButton(config: customConfig)
button.setTitle("Custom Button", for: .normal)
```

### Presets

```swift
// Primary button
let config1 = OkIDButtonConfig.primary(
    color: .systemBlue,
    icon: UIImage(systemName: "checkmark")
)

// Secondary button
let config2 = OkIDButtonConfig.secondary(
    borderColor: .systemGreen,
    titleColor: .white,
    icon: UIImage(systemName: "arrow.right")
)

// Tertiary button
let config3 = OkIDButtonConfig.tertiary(
    titleColor: .systemRed,
    icon: UIImage(systemName: "xmark")
)
```

## Loading States

All button types support loading states:

```swift
button.isLoading = true  // Shows activity indicator, hides text/icon
button.isLoading = false // Restores text/icon, hides activity indicator
```

## Touch Effects

Built-in touch effects:
- **Scale:** Button scales to 97% on touch
- **Fade:** Button fades to 80% opacity on touch
- **Animation:** Smooth 0.1s animation

## Auto Layout

All buttons use Auto Layout by default:

```swift
view.addSubview(button)
NSLayoutConstraint.activate([
    button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
    button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
    button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
])
// Height is automatically set to 56pt (or custom if specified)
```

## Examples

### Button with Loading State
```swift
let button = OkIDPrimaryButton(title: "Submit")

@objc func submitTapped() {
    button.isLoading = true
    
    Task {
        await performAsyncTask()
        button.isLoading = false
    }
}
```

### Dynamic Color Update
```swift
let button = OkIDPrimaryButton(title: "Status")

func updateStatus(isActive: Bool) {
    button.setColor(isActive ? .systemGreen : .systemRed)
    button.setTitle(isActive ? "Active" : "Inactive", for: .normal)
}
```

### Stack of Buttons
```swift
let stack = UIStackView()
stack.axis = .vertical
stack.spacing = 14

stack.addArrangedSubview(OkIDPrimaryButton(title: "Primary Action"))
stack.addArrangedSubview(OkIDSecondaryButton(title: "Secondary Action"))
stack.addArrangedSubview(OkIDTertiaryButton(title: "Cancel"))
```

## Best Practices

1. **Use Primary for main actions** (Submit, Continue, Start)
2. **Use Secondary for alternative actions** (Scan, Settings, Cancel)
3. **Use Tertiary for inline/minimal actions** (Skip, Learn More, Back)
4. **Show loading states** for async operations
5. **Keep titles concise** (2-3 words max)
6. **Use icons sparingly** to enhance meaning, not decoration

## Migration from UIButton

**Before:**
```swift
let button = UIButton(type: .system)
button.setTitle("Start", for: .normal)
button.backgroundColor = .systemBlue
button.layer.cornerRadius = 14
// ... 15 more lines of configuration
```

**After:**
```swift
let button = OkIDPrimaryButton(
    title: "Start",
    color: .systemBlue
)
```
