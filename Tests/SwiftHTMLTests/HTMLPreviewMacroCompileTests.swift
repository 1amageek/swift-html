#if canImport(WebKit)
// A single `import SwiftHTML` — no `import DeveloperToolsSupport`, no SwiftUI,
// and no `#if DEBUG` guard. `#Preview` here is SwiftHTML's own macro, which
// Xcode's canvas discovers by name.
import SwiftHTML

#Preview {
    main {
        h1 { "Hello" }
        p { "Rendered by SwiftHTML." }
    }
}

#Preview("Named") {
    div(.class("card")) {
        "Single-import preview"
    }
}
#endif
