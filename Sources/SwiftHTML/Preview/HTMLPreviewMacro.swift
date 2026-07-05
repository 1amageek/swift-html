#if canImport(WebKit)
/// Declares an Xcode preview for SwiftHTML content, usable with a single
/// `import SwiftHTML`:
///
/// ```swift
/// import SwiftHTML
///
/// #Preview {
///     main { h1 { "Hello" } }
/// }
/// ```
///
/// This is SwiftHTML's own `#Preview` macro. Xcode's canvas discovers previews
/// by the macro name `Preview`, so it appears in the canvas exactly like
/// SwiftUI's `#Preview` — but the content is HTML rendered in a `WKWebView`, and
/// there is no SwiftUI dependency. The macro expands to a
/// `DeveloperToolsSupport.PreviewRegistry` conformance gated behind
/// `#if DEBUG && canImport(WebKit)`, so it contributes nothing to a release
/// server or a WebAssembly build and never links WebKit there.
///
/// - Note: In a file that also imports SwiftUI or DeveloperToolsSupport, `#Preview`
///   is ambiguous; SwiftHTML preview files import `SwiftHTML` only.
@freestanding(declaration)
public macro Preview<Content: HTML>(
    _ name: String? = nil,
    @HTMLBuilder _ content: () -> Content
) = #externalMacro(module: "SwiftHTMLMacros", type: "HTMLPreviewMacro")
#endif
