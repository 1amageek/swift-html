// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "ClientRuntimeHTML",
    products: [
        .executable(name: "ClientRuntimeHTMLApp", targets: ["ClientRuntimeHTMLApp"]),
    ],
    dependencies: [
        .package(name: "swift-html", path: "../.."),
        .package(name: "JavaScriptKit", path: "../../../JavaScriptKit"),
    ],
    targets: [
        .executableTarget(
            name: "ClientRuntimeHTMLApp",
            dependencies: [
                .product(name: "SwiftHTMLClientRuntime", package: "swift-html"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
