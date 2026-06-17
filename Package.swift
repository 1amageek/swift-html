// swift-tools-version: 6.3

import CompilerPluginSupport
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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftHTMLPreviewMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftHTML",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftHTMLPreview",
            dependencies: [
                "SwiftHTML",
                "SwiftHTMLPreviewMacros",
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
                "SwiftHTMLPreviewMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
