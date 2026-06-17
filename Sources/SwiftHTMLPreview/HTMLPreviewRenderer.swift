import SwiftHTML

public struct HTMLPreviewRenderer: Sendable {
    public var stylesheet: Stylesheet
    public var language: String
    public var renderOptions: HTMLRenderOptions

    public init(
        stylesheet: Stylesheet = HTMLPreviewRenderer.defaultStylesheet,
        language: String = "en",
        renderOptions: HTMLRenderOptions = .development
    ) {
        self.stylesheet = stylesheet
        self.language = language
        self.renderOptions = renderOptions
    }

    public func render(_ content: some HTML) -> String {
        HTMLPreviewDocument(
            title: "SwiftHTML Preview",
            style: stylesheet.cssText,
            language: language,
            content: content
        )
        .renderArtifact(options: renderOptions)
        .html
    }

    public static let defaultStylesheet = Stylesheet {
        rule(":root") {
            .colorScheme("light dark")
            .fontFamily("-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"Helvetica Neue\", sans-serif")
            .background("Canvas")
            .color("CanvasText")
        }

        rule("html, body") {
            .minHeight("100%")
            .margin("0")
        }

        rule("body") {
            .boxSizing("border-box")
            .padding("24px")
        }

        rule("*, *::before, *::after") {
            .boxSizing("inherit")
        }
    }
}
