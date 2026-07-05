#if DEBUG && canImport(WebKit)
import SwiftHTMLPreview
import Testing

@Suite
struct SwiftHTMLPreviewReExportTests {
    // Verifies the compatibility re-export still surfaces the SwiftHTML preview
    // types through `import SwiftHTMLPreview` alone. The `#Preview` macro itself
    // requires `import SwiftHTML` (a re-exported macro is not forwarded through a
    // second `@_exported` hop).
    @Test
    func reExportsPreviewSurface() {
        let html = HTMLPreviewRenderer().render(div(.class("card")) {
            "Re-export"
        })

        #expect(html.contains("<div class=\"card\">Re-export</div>"))
    }
}
#endif
