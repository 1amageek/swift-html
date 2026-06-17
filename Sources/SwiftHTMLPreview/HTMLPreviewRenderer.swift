import SwiftHTML

public struct HTMLPreviewRenderer: Sendable {
    public var configuration: HTMLPreviewConfiguration

    public init(configuration: HTMLPreviewConfiguration = .default) {
        self.configuration = configuration
    }

    public func render(_ content: some HTML, title: String? = nil) -> String {
        HTMLPreviewDocument(
            title: title ?? "SwiftHTML Preview",
            configuration: configuration,
            content: content
        )
        .renderArtifact(options: configuration.renderOptions)
        .html
    }
}
