# OkID Alert Controller

Custom alert controller utility for consistent alert presentation throughout the SDK.

## Usage

### Basic Alerts

```swift
// Simple alert with OK button
OkIDAlert.show(
    title: "Information",
    message: "Your verification is complete",
    from: self
)

// Error alert
OkIDAlert.showError(
    message: "Failed to process verification",
    from: self
)

// Success alert
OkIDAlert.showSuccess(
    message: "Verification completed successfully",
    from: self
)

// Warning alert
OkIDAlert.showWarning(
    message: "Document will expire soon",
    from: self
)
```

### Confirmation Alerts

```swift
// Standard confirmation
OkIDAlert.showConfirmation(
    title: "Cancel Verification",
    message: "Are you sure you want to cancel?",
    confirmTitle: "Yes",
    from: self,
    onConfirm: {
        // Handle confirmation
    },
    onCancel: {
        // Handle cancellation
    }
)

// Destructive confirmation (e.g., delete)
OkIDAlert.showDestructiveConfirmation(
    title: "Delete Profile?",
    message: "This will permanently delete all your data.",
    destructiveTitle: "Delete",
    from: self,
    onConfirm: {
        // Handle deletion
    }
)
```

### Custom Actions

```swift
// Alert with custom actions
OkIDAlert.show(
    title: "Choose Action",
    message: "What would you like to do?",
    actions: [
        .cancel(),
        .tryAgain { 
            // Retry logic
        },
        .continueAction {
            // Continue logic
        }
    ],
    from: self
)

// Custom action
let customAction = OkIDAlert.Action(
    title: "Skip",
    style: .default
) {
    // Handle skip
}
```

### Action Sheet

```swift
OkIDAlert.showActionSheet(
    title: "Select Option",
    actions: [
        OkIDAlert.Action(title: "Option 1", style: .default) {
            // Handle option 1
        },
        OkIDAlert.Action(title: "Option 2", style: .default) {
            // Handle option 2
        },
        OkIDAlert.Action(title: "Delete", style: .destructive) {
            // Handle delete
        },
        .cancel()
    ],
    from: self,
    sourceView: button // For iPad popover positioning
)
```

### Text Input Alert

```swift
OkIDAlert.showTextInput(
    title: "Enter PIN",
    message: "Please enter your 4-digit PIN",
    placeholder: "PIN",
    keyboardType: .numberPad,
    submitTitle: "Submit",
    from: self,
    onSubmit: { text in
        guard let pin = text else { return }
        // Handle PIN input
    }
)
```

## UIViewController Extension

For convenience, you can also use the extension methods directly on any `UIViewController`:

```swift
// Simple alerts
self.showAlert(title: "Info", message: "Message")
self.showError("Error message")
self.showSuccess("Success message")
self.showWarning("Warning message")

// Confirmation
self.showConfirmation(
    title: "Confirm",
    message: "Are you sure?",
    onConfirm: { 
        // Handle confirmation 
    }
)

// Destructive confirmation
self.showDestructiveConfirmation(
    title: "Delete?",
    message: "This cannot be undone",
    onConfirm: { 
        // Handle deletion 
    }
)

// Action sheet
self.showActionSheet(
    title: "Options",
    actions: [
        .cancel(),
        .confirm("Select") { /* ... */ }
    ]
)
```

## Preset Actions

Common actions are available as static methods:

- `.ok(handler:)` - OK button
- `.cancel(handler:)` - Cancel button
- `.confirm(title:handler:)` - Confirm button (customizable title)
- `.delete(handler:)` - Destructive delete button
- `.tryAgain(handler:)` - Try Again button
- `.continueAction(handler:)` - Continue button

## Alert Styles

The `AlertStyle` enum provides semantic styling (currently for documentation, can be extended for visual indicators):

- `.info` - Informational alerts
- `.success` - Success messages
- `.warning` - Warning messages
- `.error` - Error messages

## Migration from UIAlertController

Replace existing `UIAlertController` usage:

### Before
```swift
let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
alert.addAction(UIAlertAction(title: "OK", style: .default))
present(alert, animated: true)
```

### After
```swift
OkIDAlert.showError(message: message, from: self)
// or
self.showError(message)
```

### Before (Confirmation)
```swift
let alert = UIAlertController(title: "Delete?", message: "Are you sure?", preferredStyle: .alert)
alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
    // Handle delete
})
present(alert, animated: true)
```

### After
```swift
self.showDestructiveConfirmation(
    title: "Delete?",
    message: "Are you sure?",
    onConfirm: {
        // Handle delete
    }
)
```
