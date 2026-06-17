import CoreGraphics
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
    private let title: String?
    private let configuration: HTMLPreviewConfiguration
    private let content: Content

    public init(
        _ title: String? = nil,
        configuration: HTMLPreviewConfiguration = .default,
        @HTMLBuilder content: () -> Content
    ) {
        self.title = title
        self.configuration = configuration
        self.content = content()
    }

    public var body: some View {
        previewBody
            .frame(
                width: frameWidth,
                height: frameHeight
            )
    }

    @ViewBuilder
    private var previewBody: some View {
        #if canImport(WebKit) && (os(macOS) || canImport(UIKit))
        HTMLPreviewWebView(
            html: renderedHTML,
            baseURL: configuration.baseURL
        )
        #else
        Text(renderedHTML)
        #endif
    }

    private var renderedHTML: String {
        HTMLPreviewRenderer(configuration: configuration).render(content, title: title)
    }

    private var frameWidth: CGFloat? {
        guard let width = configuration.viewport.width else {
            return nil
        }
        return CGFloat(width)
    }

    private var frameHeight: CGFloat? {
        guard let height = configuration.viewport.height else {
            return nil
        }
        return CGFloat(height)
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
