# NFC Setup Required for Host App

## ⚠️ Error: Sandbox Restriction - NFC Not Configured

The errors you're seeing indicate that the **host app** (the app that integrates this SDK) needs proper NFC configuration.

```
XPC Error: Code=4099 "The connection to service named com.apple.nfcd.service.corenfc was invalidated"
Error 159 - Sandbox restriction
```

## Required Setup Steps

### 1. Enable NFC Capability in Xcode

**In your host app project (not the SDK):**

1. Open your app's `.xcodeproj` or `.xcworkspace`
2. Select your app target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"**
5. Add **"Near Field Communication Tag Reading"**

### 2. Add Info.plist Entries

Add these keys to your host app's `Info.plist`:

```xml
<!-- Required: NFC Usage Description -->
<key>NFCReaderUsageDescription</key>
<string>This app needs NFC to read passport data for identity verification</string>

<!-- Required: ISO7816 application identifiers for passport reading -->
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>  <!-- eMRTD application -->
    <string>A0000002472001</string>  <!-- Additional passport ID -->
</array>
```

### 3. Create/Update Entitlements File

Your app needs an entitlements file (e.g., `YourApp.entitlements`) with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- NFC Tag Reading -->
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>TAG</string>
    </array>
    
    <!-- ISO7816 for passport -->
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>A0000002472001</string>
    </array>
</dict>
</plist>
```

### 4. Verify Entitlements File is Linked

In Xcode:
1. Select your app target
2. Go to **"Build Settings"**
3. Search for "Code Signing Entitlements"
4. Ensure it points to your `.entitlements` file (e.g., `YourApp/YourApp.entitlements`)

## Complete Info.plist Example

Here's a complete example with all required NFC keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys... -->
    
    <!-- NFC REQUIRED KEYS -->
    <key>NFCReaderUsageDescription</key>
    <string>Read passport NFC chip for identity verification</string>
    
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A0000002471001</string>
        <string>A0000002472001</string>
    </array>
    
    <!-- CAMERA REQUIRED for MRZ scanning -->
    <key>NSCameraUsageDescription</key>
    <string>Camera is needed to scan passport MRZ and capture photos</string>
</dict>
</plist>
```

## Testing NFC

After configuration:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run on Physical Device**: NFC **only works on real iPhones** (iPhone 7 and later)
4. **Test**: Tap "Scan Passport MRZ" in the NFC input screen

## Device Requirements

✅ **Supported:**
- iPhone 7 and later
- iOS 13.0+
- Physical device only (not simulator)

❌ **Not Supported:**
- iOS Simulator (no NFC hardware)
- iPhones older than iPhone 7

## Troubleshooting

### Still Getting Sandbox Errors?

1. **Verify capability is enabled:**
   - Target → Signing & Capabilities
   - "Near Field Communication Tag Reading" should be visible

2. **Check entitlements:**
   ```bash
   codesign -d --entitlements - YourApp.app
   ```
   Should show NFC entitlements

3. **Verify Info.plist:**
   ```bash
   /usr/libexec/PlistBuddy -c "Print :NFCReaderUsageDescription" Info.plist
   ```

4. **Clean derived data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

### Error 159 Persists?

This means entitlements are missing or incorrect:

- ✅ Check entitlements file path in Build Settings
- ✅ Verify provisioning profile includes NFC capability
- ✅ Re-sign the app with proper entitlements
- ✅ Delete app from device and reinstall

## Example Host App Setup

If you need a reference, here's a minimal host app configuration:

**Info.plist:**
```xml
<key>NFCReaderUsageDescription</key>
<string>NFC passport reading</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
    <string>A0000002472001</string>
</array>
```

**YourApp.entitlements:**
```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>TAG</string>
</array>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
    <string>A0000002472001</string>
</array>
```

**Xcode Capability:**
- ✅ Near Field Communication Tag Reading

## SDK Note

This SDK (**OkIDVerificationSDK**) is properly configured to **use** NFC when available. The errors occur because the **host app** hasn't been configured with the required NFC permissions and entitlements.

Once you add these configurations to your host app, the NFC functionality will work correctly!

## Quick Checklist

- [ ] Added "Near Field Communication Tag Reading" capability in Xcode
- [ ] Added `NFCReaderUsageDescription` to Info.plist
- [ ] Added `com.apple.developer.nfc.readersession.iso7816.select-identifiers` to Info.plist
- [ ] Created/updated `.entitlements` file with NFC keys
- [ ] Linked entitlements file in Build Settings
- [ ] Cleaned build folder
- [ ] Testing on iPhone 7 or later (physical device)
- [ ] Deleted and reinstalled app after changes

After completing this checklist, NFC should work without sandbox errors! ✅

