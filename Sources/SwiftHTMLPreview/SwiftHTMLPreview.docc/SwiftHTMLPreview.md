# ``SwiftHTMLPreview``

Compatibility re-export of the SwiftHTML preview surface.

## Overview

The SwiftHTML preview surface — the `#Preview` macro and the `HTMLPreview`
renderer — now lives in ``SwiftHTML``. `SwiftHTMLPreview` re-exports `SwiftHTML`
so existing `import SwiftHTMLPreview` code keeps compiling; new code should
`import SwiftHTML` directly.

Mark the HTML you want to inspect with `#Preview`. It renders the content in
a `WKWebView` inside Xcode's canvas through a `DeveloperToolsSupport`
`PreviewRegistry` conformance — the same discovery mechanism as SwiftUI's
`#Preview`, but with no SwiftUI dependency. The expansion is self-gated behind
`#if DEBUG && canImport(WebKit)`, so it contributes nothing to a release server
or a WebAssembly build.

```swift
import SwiftHTML

#Preview {
    main(.class("dashboard-shell")) {
        header(.class("dashboard-header")) {
            p(.class("eyebrow"), text: "SwiftHTML Preview")
            h1("Release Operations")
            p("Inspect layout, copy, and CSS directly in Xcode.")
        }
    }
}
```

For a named preview, layout traits, or document settings (stylesheet, language,
base URL, render options), call the `HTMLPreview(...)` function inside Apple's
`#Preview`. That macro comes from `DeveloperToolsSupport`, so the file imports
both:

```swift
import SwiftHTML
import DeveloperToolsSupport

#Preview("Mobile", traits: .fixedLayout(width: 390, height: 844)) {
    HTMLPreview(language: "ja") {
        main(.class("page")) {
            h1("Mobile Preview")
            p("Xcode Preview で HTML を確認できます。")
        }
    }
}
```
