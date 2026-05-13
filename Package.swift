// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "OkIDVerificationSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "OkIDVerificationSDK",
            targets: ["OkIDVerificationSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OkIDVerificationSDK",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources/document_detection_320.mlpackage"),
                .process("Resources/age_gender_model.mlpackage")
            ]
        ),
    ]
)

