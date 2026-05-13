Pod::Spec.new do |spec|
  spec.name                  = "OkIDVerificationSDK"
  spec.version               = "1.0.0"
  spec.summary               = "Pure native iOS SDK for identity verification with async/await support"
  spec.description           = <<-DESC
    OkID Verification SDK provides comprehensive identity verification features including:
    - Document capture and verification (passport, ID card, driver's license)
    - Liveness detection with face recognition
    - NFC passport reading for ePassport chips
    - QR code integration
    - Profile management with secure storage
    - Modern async/await Swift concurrency
    - Customizable UI and theming
  DESC
  
  spec.homepage              = "https://github.com/okid/okid-verification-sdk-ios"
  spec.license               = { :type => "MIT", :file => "LICENSE" }
  spec.author                = { "OkID" => "support@okid.com" }
  spec.source                = { :git => "https://github.com/okid/okid-verification-sdk-ios.git", :tag => "#{spec.version}" }
  
  spec.ios.deployment_target = "15.0"
  spec.swift_versions        = ["5.7", "5.8", "5.9"]
  
  spec.source_files          = "Sources/**/*.swift"
  spec.resources             = "Sources/Resources/**/*"
  spec.resource_bundles      = {
    'OkIDVerificationSDK' => ['Sources/Resources/**/*.mlpackage']
  }
  
  spec.frameworks            = "UIKit", "AVFoundation", "CoreML", "Vision", "CoreNFC", "Security"
  spec.requires_arc          = true
  
  spec.pod_target_xcconfig   = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.7'
  }
  
  # Required capabilities
  spec.info_plist = {
    'NSCameraUsageDescription' => 'Camera access is required for document and selfie capture',
    'NSPhotoLibraryUsageDescription' => 'Photo library access is required to save captured images',
    'NFCReaderUsageDescription' => 'NFC access is required to read passport data'
  }
end
