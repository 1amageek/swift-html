#if DEBUG && canImport(WebKit)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import WebKit
import DeveloperToolsSupport

// SPI used by the `#Preview` macro expansion. The expansion names only these
// `SwiftHTML` symbols, so `import SwiftHTML` alone is enough to write a preview
// while WebKit and DeveloperToolsSupport stay regular (non-`@_exported`) imports
// here. An `@_exported import` of those modules would leak them into every
// package that re-exports SwiftHTML (e.g. a server runtime), which is enough to
// break unrelated type lookups downstream.
public typealias _HTMLPreviewRegistry = DeveloperToolsSupport.PreviewRegistry
public typealias _HTMLPreviewValue = DeveloperToolsSupport.Preview

/// Builds the `DeveloperToolsSupport.Preview` that the `#Preview` macro registers.
/// Called only from the macro expansion.
@MainActor
public func _makeHTMLPreview<Content: HTML>(
    _ name: String? = nil,
    @HTMLBuilder _ content: () -> Content
) -> DeveloperToolsSupport.Preview {
    let webView = HTMLPreview(content: content)
    if let name {
        return DeveloperToolsSupport.Preview(name) { webView }
    }
    return DeveloperToolsSupport.Preview { webView }
}

/// A WebKit-backed preview surface for SwiftHTML content.
///
/// `import SwiftHTML` and write `#Preview { ... }` — SwiftHTML's own `#Preview`
/// macro renders the HTML in a `WKWebView`. This function is the rendering
/// primitive the macro uses; call it directly to obtain a `WKWebView` for
/// SwiftHTML content, configured through parameters:
///
/// ```swift
/// let webView = HTMLPreview(language: "ja") {
///     main { "こんにちは" }
/// }
/// ```
///
/// The content renders to a full HTML document. There is no SwiftUI dependency,
/// and the surface is gated behind `#if DEBUG && canImport(WebKit)`, so it never
/// links into a release server or a WebAssembly build.
@MainActor
public func HTMLPreview<Content: HTML>(
    language: String = "en",
    stylesheet: Stylesheet = HTMLPreviewRenderer.defaultStylesheet,
    baseURL: URL? = nil,
    renderOptions: HTMLRenderOptions = .development,
    @HTMLBuilder content: () -> Content
) -> WKWebView {
    let renderer = HTMLPreviewRenderer(
        stylesheet: stylesheet,
        language: language,
        renderOptions: renderOptions
    )
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.loadHTMLString(renderer.render(content()), baseURL: baseURL)
    return webView
}
#endif
