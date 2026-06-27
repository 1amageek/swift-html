// swift-tools-version: 6.3

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency"),
]

let clientRuntimeProfile = Context.environment["SWIFTHTML_CLIENT_RUNTIME_PROFILE"]
let clientRuntimeSwiftSettings: [SwiftSetting] = swiftSettings
    + (clientRuntimeProfile == "embedded"
        ? [
            .enableExperimentalFeature("Embedded"),
            .unsafeFlags(["-Xfrontend", "-emit-empty-object-file"]),
        ] : [])

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
        .library(name: "SwiftHTMLClientRuntime", targets: ["SwiftHTMLClientRuntime"]),
        .library(name: "SwiftHTMLPreview", targets: ["SwiftHTMLPreview"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftHTML",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftHTMLClientRuntime",
            swiftSettings: clientRuntimeSwiftSettings
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
            name: "SwiftHTMLClientRuntimeTests",
            dependencies: ["SwiftHTMLClientRuntime"],
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
