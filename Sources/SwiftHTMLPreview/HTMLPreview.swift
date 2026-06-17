import Foundation
import SwiftHTML
import SwiftUI

@MainActor
public struct HTMLPreview<Content: HTML>: View {
    private let title: String?
    private var baseURLValue: URL?
    private var styleText: String
    private var languageCode: String
    private var renderOptionsValue: HTMLRenderOptions
    private let content: Content

    public init(
        _ title: String? = nil,
        @HTMLBuilder content: () -> Content
    ) {
        self.title = title
        self.baseURLValue = nil
        self.styleText = HTMLPreviewRenderer.defaultStyle
        self.languageCode = "en"
        self.renderOptionsValue = .development
        self.content = content()
    }

    public var body: some View {
        HTMLPreviewHost(
            title,
            baseURL: baseURLValue,
            style: styleText,
            language: languageCode,
            renderOptions: renderOptionsValue
        ) {
            content
        }
    }

    public func baseURL(_ url: URL?) -> HTMLPreview {
        var copy = self
        copy.baseURLValue = url
        return copy
    }

    public func language(_ language: String) -> HTMLPreview {
        var copy = self
        copy.languageCode = language
        return copy
    }

    public func renderOptions(_ options: HTMLRenderOptions) -> HTMLPreview {
        var copy = self
        copy.renderOptionsValue = options
        return copy
    }

    public func style(_ css: String) -> HTMLPreview {
        var copy = self
        copy.styleText = css
        return copy
    }
}
