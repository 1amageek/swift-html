#if DEBUG && canImport(WebKit)
import Foundation
// Re-exported (debug + Apple only) so the `#HTMLPreview` expansion — which cannot
// introduce its own imports — can name `WKWebView` and the
// `DeveloperToolsSupport` preview registry through `import SwiftHTML` alone.
@_exported import WebKit
@_exported import DeveloperToolsSupport

/// A WebKit-backed preview surface for SwiftHTML content.
///
/// Return it from Xcode's `#Preview` macro the same way you would a SwiftUI
/// view. `import SwiftHTML` provides `HTMLPreview`; the `#Preview` macro comes
/// from Apple's `DeveloperToolsSupport` (just as SwiftUI's `#Preview` needs
/// `import SwiftUI`), so a preview file imports both:
///
/// ```swift
/// import SwiftHTML
///
/// #if DEBUG && canImport(WebKit)
/// import DeveloperToolsSupport
///
/// #Preview {
///     HTMLPreview {
///         main { h1 { "Hello" } }
///     }
/// }
/// #endif
/// ```
///
/// The content renders to a full HTML document shown in a `WKWebView`. There is
/// no SwiftUI dependency, and the surface is gated behind
/// `#if DEBUG && canImport(WebKit)`, so it never links into a release server or
/// a WebAssembly build.
///
/// - Note: `HTMLPreview` returns a `WKWebView` rather than a bespoke subclass so
///   the closure resolves directly against `#Preview`'s AppKit/UIKit overload.
///   Styling and locale are configured through parameters:
///
///   ```swift
///   #Preview {
///       HTMLPreview(language: "ja", stylesheet: Stylesheet { rule("body") { .margin("0") } }) {
///           main { "こんにちは" }
///       }
///   }
///   ```
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
