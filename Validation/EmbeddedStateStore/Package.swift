// swift-tools-version: 6.4

import PackageDescription

let baseSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("Extern"),
    .enableUpcomingFeature("ApproachableConcurrency"),
]

let swiftSettings = baseSwiftSettings + (Context.environment["SWIFT_HTML_EMBEDDED"] == "1"
    ? [.enableExperimentalFeature("Embedded")]
    : [])

let linkerSettings: [LinkerSetting] = {
    guard let unicodeTables = Context.environment["SWIFT_HTML_UNICODE_TABLES"] else {
        return []
    }
    return [.unsafeFlags(["-Xlinker", unicodeTables])]
}()

let package = Package(
    name: "EmbeddedStateStoreValidation",
    products: [
        .executable(name: "EmbeddedStateStoreValidation", targets: ["EmbeddedStateStoreValidation"]),
    ],
    targets: [
        .target(
            name: "SwiftHTML",
            exclude: ["DESIGN.md"],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "EmbeddedStateStoreValidation",
            dependencies: ["SwiftHTML"],
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
