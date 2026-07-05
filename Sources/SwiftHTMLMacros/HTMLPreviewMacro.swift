import SwiftSyntax
import SwiftSyntaxMacros

/// Expands `#Preview { ... }` (SwiftHTML's own preview macro) into a
/// `DeveloperToolsSupport.PreviewRegistry` conformance that renders the HTML in
/// a `WKWebView`.
///
/// Xcode's canvas discovers previews by the macro name `Preview`, so this
/// macro appears in the canvas exactly like SwiftUI's `#Preview` — but with no
/// SwiftUI dependency. The expansion is self-gated behind
/// `#if DEBUG && canImport(WebKit)`, so a release or WebAssembly build produces
/// no code and never links WebKit. The macro emits no `import` statements (a
/// macro cannot introduce one); the referenced types are made visible by
/// `SwiftHTML`'s gated `@_exported import` of `DeveloperToolsSupport` and
/// `WebKit`.
public struct HTMLPreviewMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let closure = node.trailingClosure else {
            throw MacroExpansionErrorMessage(
                "#Preview requires a trailing closure containing the HTML to preview."
            )
        }

        let registryType = context.makeUniqueName("Preview")

        guard let location = context.location(of: node) else {
            throw MacroExpansionErrorMessage(
                "#Preview could not resolve its source location."
            )
        }

        // An optional leading string argument is the preview's display name.
        let previewInit: String
        if let name = node.arguments.first?.expression {
            previewInit = "DeveloperToolsSupport.Preview(\(name.trimmed))"
        } else {
            previewInit = "DeveloperToolsSupport.Preview"
        }

        return ["""
        #if DEBUG && canImport(WebKit)
        @available(macOS 14.0, iOS 17.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *)
        nonisolated struct \(registryType): DeveloperToolsSupport.PreviewRegistry {
            static var fileID: Swift.String { \(location.file) }
            static var line: Swift.Int { \(location.line) }
            static var column: Swift.Int { \(location.column) }
            @MainActor static func makePreview() throws -> DeveloperToolsSupport.Preview {
                \(raw: previewInit) {
                    SwiftHTML.HTMLPreview\(closure)
                }
            }
        }
        #endif
        """]
    }
}
