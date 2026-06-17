// swift-tools-version: 6.3

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency"),
]

let package = Package(
    name: "swift-html",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "SwiftHTML", targets: ["SwiftHTML"]),
        .library(name: "SwiftHTMLPreview", targets: ["SwiftHTMLPreview"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftHTML",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftHTMLPreview",
            dependencies: [
                "SwiftHTML",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SwiftHTMLTests",
            dependencies: ["SwiftHTML"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SwiftHTMLPreviewTests",
            dependencies: [
                "SwiftHTML",
                "SwiftHTMLPreview",
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
