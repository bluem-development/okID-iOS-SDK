# OkID Bar Button Components

Custom factory for creating consistently styled `UIBarButtonItem` instances across the OkID Verification SDK.

## Overview

`OkIDBarButtonItem` provides static factory methods for creating common navigation bar button items with consistent styling, particularly optimized for navigation bars with teal backgrounds and white tint colors.

## Usage

### Close Button (X icon)

```swift
navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
    target: self,
    action: #selector(closeTapped)
)
```

### Back Button (Chevron icon)

```swift
navigationItem.leftBarButtonItem = OkIDBarButtonItem.back(
    target: self,
    action: #selector(backTapped)
)
```

### Delete Button (Trash icon)

```swift
navigationItem.rightBarButtonItem = OkIDBarButtonItem.delete(
    target: self,
    action: #selector(deleteTapped)
)
```

### Torch Button (Flashlight icon)

```swift
// Off state
navigationItem.rightBarButtonItem = OkIDBarButtonItem.torch(
    target: self,
    action: #selector(toggleTorch),
    isOn: false
)

// On state
navigationItem.rightBarButtonItem = OkIDBarButtonItem.torch(
    target: self,
    action: #selector(toggleTorch),
    isOn: true
)
```

### Done Button

```swift
let doneButton = OkIDBarButtonItem.done(
    target: self,
    action: #selector(doneTapped)
)
```

### Space Items

```swift
// Flexible space
let flexSpace = OkIDBarButtonItem.flexibleSpace()

// Fixed space
let fixedSpace = OkIDBarButtonItem.fixedSpace(width: 20)

// Toolbar with spacing
toolbar.setItems([flexSpace, doneButton], animated: false)
```

### Custom Icon Button

```swift
navigationItem.rightBarButtonItem = OkIDBarButtonItem.custom(
    icon: "gear",
    target: self,
    action: #selector(settingsTapped)
)
```

### Custom Text Button

```swift
navigationItem.rightBarButtonItem = OkIDBarButtonItem.custom(
    title: "Save",
    target: self,
    action: #selector(saveTapped)
)
```

### Custom Tint Color

All factory methods support optional custom tint colors:

```swift
// Red delete button
let deleteButton = OkIDBarButtonItem.delete(
    target: self,
    action: #selector(deleteTapped),
    tintColor: .systemRed
)

// Blue custom button
let customButton = OkIDBarButtonItem.custom(
    icon: "star.fill",
    target: self,
    action: #selector(starTapped),
    tintColor: .systemBlue
)
```

## Factory Methods

- `close(target:action:tintColor:)` - Close button (xmark icon)
- `back(target:action:tintColor:)` - Back button (chevron.left icon)
- `delete(target:action:tintColor:)` - Delete button (trash icon)
- `torch(target:action:isOn:tintColor:)` - Torch/flashlight toggle button
- `done(target:action:tintColor:)` - System done button
- `flexibleSpace()` - Flexible spacing item
- `fixedSpace(width:)` - Fixed width spacing item
- `custom(icon:target:action:tintColor:)` - Custom icon button
- `custom(title:target:action:tintColor:)` - Custom text button

## Default Styling

- **Default tint color**: White (`.white`)
- **Style**: Plain (`.plain`)
- **Icon type**: SF Symbols

## Integration Example

```swift
import UIKit
import OkIDVerificationSDK

class MyViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add close button
        navigationItem.leftBarButtonItem = OkIDBarButtonItem.close(
            target: self,
            action: #selector(closeTapped)
        )
        
        // Add custom action button
        navigationItem.rightBarButtonItem = OkIDBarButtonItem.custom(
            icon: "checkmark.circle",
            target: self,
            action: #selector(confirmTapped)
        )
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmTapped() {
        // Handle confirmation
    }
}
```

## Notes

- All factory methods return standard `UIBarButtonItem` instances
- Compatible with iOS 13+
- Designed to work with SDK's teal primary color (`#4ECDC4`)
- Icons use SF Symbols for consistency
