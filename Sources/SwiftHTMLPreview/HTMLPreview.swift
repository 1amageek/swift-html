import Foundation
import SwiftHTML
import SwiftUI

@MainActor
public struct HTMLPreview<Content: HTML>: View {
    private var baseURLValue: URL?
    private var stylesheetValue: Stylesheet
    private var languageCode: String
    private var renderOptionsValue: HTMLRenderOptions
    private let content: Content

    public init(
        @HTMLBuilder content: () -> Content
    ) {
        self.baseURLValue = nil
        self.stylesheetValue = HTMLPreviewRenderer.defaultStylesheet
        self.languageCode = "en"
        self.renderOptionsValue = .development
        self.content = content()
    }

    public var body: some View {
        HTMLPreviewHost(
            baseURL: baseURLValue,
            stylesheet: stylesheetValue,
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

    public func style(_ stylesheet: Stylesheet) -> HTMLPreview {
        var copy = self
        copy.stylesheetValue = stylesheet
        return copy
    }

    public func style(@StylesheetBuilder _ stylesheet: () -> Stylesheet) -> HTMLPreview {
        var copy = self
        copy.stylesheetValue = stylesheet()
        return copy
    }
}
