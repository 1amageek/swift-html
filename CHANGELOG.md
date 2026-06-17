# Changelog

## 0.2.0 - 2026-06-17

Adds Xcode preview support for SwiftHTML.

| Area | Included |
|---|---|
| Preview | New `SwiftHTMLPreview` product with `#HTMLPreview`, `HTMLPreviewHost`, `HTMLPreviewRenderer`, `HTMLPreviewConfiguration`, and `HTMLPreviewViewport`. |
| Macro | New `SwiftHTMLPreviewMacros` target that expands `#HTMLPreview` directly to SwiftUI `#Preview` while forwarding preview traits. |
| Documentation | README and DocC coverage for preview usage, configuration, and build behavior. |
| Tests | Preview renderer tests, compile smoke tests, and macro expansion tests. |
| Tooling | Swift package tools version remains Swift 6.3. |

## 0.1.0 - 2026-06-16

Initial public release.

| Area | Included |
|---|---|
| HTML DSL | Lowercase HTML tags, typed attributes, text initializer shortcuts, raw HTML, and builder control flow. |
| Components | `Component`, `ServerComponent`, `ClientComponent`, `@State`, `Binding`, and environment propagation. |
| Rendering | HTML string rendering, render artifacts, diagnostics, hydration manifests, and internal graph diffing. |
| CSS | `Style`, generated standard CSS property helpers, `@StyleBuilder`, `Stylesheet`, `CSSRule`, and `@StylesheetBuilder`. |
| Hydration | Browser hydration indexes, DOM patch commands, command batches, and browser host contracts. |
| Loading | Split WASM bundle manifests, load plans, and loading runtime contracts. |
| Actions | `ActionRepresentable`, `Action`, `ActionField`, and hidden-field rendering contracts. |
