// `SwiftHTMLPreview` is a compatibility re-export.
//
// The preview surface (`HTMLPreview`, `HTMLPreviewRenderer`) now lives in
// `SwiftHTML`, so `import SwiftHTML` is the canonical path: it brings both the
// `HTMLPreview` type and the `#Preview` macro into scope.
//
// This module re-exports `SwiftHTML` so existing `import SwiftHTMLPreview` code
// keeps resolving the preview types. Note that a re-exported macro is not
// forwarded through a second `@_exported` hop, so a file that writes `#Preview`
// should `import SwiftHTML` directly.
@_exported import SwiftHTML
