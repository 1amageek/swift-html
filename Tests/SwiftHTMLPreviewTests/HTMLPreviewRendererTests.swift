import SwiftHTML
import SwiftHTMLPreview
import Testing

@Suite
struct HTMLPreviewRendererTests {
    @Test
    func rendersPreviewDocument() {
        let renderer = HTMLPreviewRenderer()
        let html = renderer.render(div(.class("card")) {
            "Preview"
        })

        #expect(html.contains("<!doctype html>"))
        #expect(html.contains("<html lang=\"en\">"))
        #expect(html.contains("<title>SwiftHTML Preview</title>"))
        #expect(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"))
        #expect(html.contains("<style>"))
        #expect(html.contains("<div class=\"card\">Preview</div>"))
    }

    @Test
    func usesCustomBaseStyle() {
        let renderer = HTMLPreviewRenderer(
            stylesheet: Stylesheet {
                rule("body") {
                    .padding("0")
                }
            }
        )
        let html = renderer.render(main {
            "Custom"
        })

        #expect(html.contains("body {\n  padding: 0;\n}"))
        #expect(html.contains("<main>Custom</main>"))
    }

    @Test
    func usesConfiguredLanguage() {
        let renderer = HTMLPreviewRenderer(language: "ja")
        let html = renderer.render(article {
            "Language"
        })

        #expect(html.contains("<html lang=\"ja\">"))
        #expect(html.contains("<article>Language</article>"))
    }
}
