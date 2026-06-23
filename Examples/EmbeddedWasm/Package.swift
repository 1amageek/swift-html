// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "EmbeddedSwiftHTML",
    products: [
        .executable(name: "EmbeddedSwiftHTMLApp", targets: ["EmbeddedSwiftHTMLApp"]),
    ],
    dependencies: [
        .package(name: "swift-html", path: "../.."),
        .package(name: "JavaScriptKit", path: "../../../JavaScriptKit"),
    ],
    targets: [
        .executableTarget(
            name: "EmbeddedSwiftHTMLApp",
            dependencies: [
                .product(name: "SwiftHTMLEmbedded", package: "swift-html"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
