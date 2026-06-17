import SwiftHTML

public struct HTMLPreviewRenderer: Sendable {
    public var style: String
    public var language: String
    public var renderOptions: HTMLRenderOptions

    public init(
        style: String = HTMLPreviewRenderer.defaultStyle,
        language: String = "en",
        renderOptions: HTMLRenderOptions = .development
    ) {
        self.style = style
        self.language = language
        self.renderOptions = renderOptions
    }

    public func render(_ content: some HTML, title: String? = nil) -> String {
        HTMLPreviewDocument(
            title: title ?? "SwiftHTML Preview",
            style: style,
            language: language,
            content: content
        )
        .renderArtifact(options: renderOptions)
        .html
    }

    public static let defaultStyle = """
    :root {
      color-scheme: light dark;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
      background: Canvas;
      color: CanvasText;
    }

    html,
    body {
      min-height: 100%;
      margin: 0;
    }

    body {
      box-sizing: border-box;
      padding: 24px;
    }

    *,
    *::before,
    *::after {
      box-sizing: inherit;
    }
    """
}
