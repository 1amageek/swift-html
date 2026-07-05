// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

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

// The `#HTMLPreview` macro plugin is a host-only build tool. `SwiftHTML` depends
// on it only on Apple platforms so cross-compiled (WebAssembly / Linux) builds —
// including the vendored copies produced by downstream WASM package generation —
// never require the plugin or swift-syntax.
let applePlatforms: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .visionOS]

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
    dependencies: [
        // Pinned to 602 to stay compatible with downstream packages (Vapor pins
        // swift-syntax to the 602 major), so swift-web can depend on swift-html.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftHTMLMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SwiftHTML",
            dependencies: [
                .target(name: "SwiftHTMLMacros", condition: .when(platforms: applePlatforms)),
            ],
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
                "SwiftHTMLPreview",
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
