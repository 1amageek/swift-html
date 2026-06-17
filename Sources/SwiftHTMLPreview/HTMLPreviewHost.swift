import Foundation
import SwiftHTML
import SwiftUI

#if canImport(WebKit)
import WebKit
#endif

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public struct HTMLPreviewHost<Content: HTML>: View {
    private let baseURL: URL?
    private let stylesheet: Stylesheet
    private let language: String
    private let renderOptions: HTMLRenderOptions
    private let content: Content

    public init(
        baseURL: URL? = nil,
        stylesheet: Stylesheet = HTMLPreviewRenderer.defaultStylesheet,
        language: String = "en",
        renderOptions: HTMLRenderOptions = .development,
        @HTMLBuilder content: () -> Content
    ) {
        self.baseURL = baseURL
        self.stylesheet = stylesheet
        self.language = language
        self.renderOptions = renderOptions
        self.content = content()
    }

    public var body: some View {
        previewBody
    }

    @ViewBuilder
    private var previewBody: some View {
        #if canImport(WebKit) && (os(macOS) || canImport(UIKit))
        HTMLPreviewWebView(
            html: renderedHTML,
            baseURL: baseURL
        )
        #else
        Text(renderedHTML)
        #endif
    }

    private var renderedHTML: String {
        HTMLPreviewRenderer(
            stylesheet: stylesheet,
            language: language,
            renderOptions: renderOptions
        )
        .render(content)
    }
}

#if canImport(WebKit) && os(macOS)
private struct HTMLPreviewWebView: NSViewRepresentable {
    typealias NSViewType = WKWebView

    let html: String
    let baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: NSViewRepresentableContext<HTMLPreviewWebView>) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateNSView(_ webView: WKWebView, context: NSViewRepresentableContext<HTMLPreviewWebView>) {
        guard context.coordinator.lastHTML != html || context.coordinator.lastBaseURL != baseURL else {
            return
        }

        context.coordinator.lastHTML = html
        context.coordinator.lastBaseURL = baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    final class Coordinator {
        var lastHTML: String?
        var lastBaseURL: URL?
    }
}
#elseif canImport(WebKit) && canImport(UIKit)
private struct HTMLPreviewWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let html: String
    let baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<HTMLPreviewWebView>) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<HTMLPreviewWebView>) {
        guard context.coordinator.lastHTML != html || context.coordinator.lastBaseURL != baseURL else {
            return
        }

        context.coordinator.lastHTML = html
        context.coordinator.lastBaseURL = baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    final class Coordinator {
        var lastHTML: String?
        var lastBaseURL: URL?
    }
}
#endif
