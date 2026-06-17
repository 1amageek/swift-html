import Foundation
import SwiftHTML

public struct HTMLPreviewConfiguration: Sendable {
    public var baseURL: URL?
    public var baseStyle: String
    public var language: String
    public var renderOptions: HTMLRenderOptions
    public var viewport: HTMLPreviewViewport

    public init(
        baseURL: URL? = nil,
        baseStyle: String = HTMLPreviewConfiguration.defaultBaseStyle,
        language: String = "en",
        renderOptions: HTMLRenderOptions = .development,
        viewport: HTMLPreviewViewport = .responsive
    ) {
        self.baseURL = baseURL
        self.baseStyle = baseStyle
        self.language = language
        self.renderOptions = renderOptions
        self.viewport = viewport
    }

    public static let `default` = HTMLPreviewConfiguration()

    public static let defaultBaseStyle = """
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
