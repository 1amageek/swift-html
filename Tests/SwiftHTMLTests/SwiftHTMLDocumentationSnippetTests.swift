import SwiftHTML
import Testing

private struct DocumentationArticleSummary: Sendable {
    let id: String
    let title: String
    let excerpt: String
    let href: String
}

private struct DocumentationArticleListPage: Component, Sendable {
    let articles: [DocumentationArticleSummary]

    var body: some HTML {
        document {
            html {
                head {
                    meta(.charset("utf-8"))
                    title("Latest Articles")
                }
                SwiftHTML.body {
                    main(.class("article-list")) {
                        h1("Latest Articles")
                        p(.class("lead"), text: "Rendered on the server with typed SwiftHTML components.")

                        section(.aria("label", "Articles")) {
                            ForEach(articles, id: { summary in summary.id }) { summary in
                                articleCard(summary)
                            }
                        }
                    }
                    .style {
                        .maxWidth("720px")
                        .margin("0 auto")
                        .padding("32px")
                        .font("16px -apple-system, BlinkMacSystemFont, sans-serif")
                    }
                }
            }
        }
    }

    private func articleCard(_ summary: DocumentationArticleSummary) -> some HTML {
        article(.class("article-card")) {
            h2 {
                a(.href(summary.href)) {
                    summary.title
                }
            }
            p(summary.excerpt)
        }
        .style {
            .padding("16px 0")
            .border("0 solid color-mix(in srgb, CanvasText 16%, transparent)")
            .custom("border-bottom-width", "1px")
        }
    }
}

private struct DocumentationInlineCounter: ClientComponent, Sendable {
    @State private var count = 0

    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Count \(count)"
        }
    }
}

@Suite
struct SwiftHTMLDocumentationSnippetTests {
    @Test
    func serverRenderedPageSnippetProducesDocumentHTML() {
        let html = DocumentationArticleListPage(
            articles: [
                DocumentationArticleSummary(
                    id: "swift-html",
                    title: "Typed HTML in Swift",
                    excerpt: "Use lowercase tags, typed attributes, and components to build HTML documents.",
                    href: "/articles/swift-html"
                ),
                DocumentationArticleSummary(
                    id: "hydration",
                    title: "Hydration Contracts",
                    excerpt: "Render artifacts carry state, event, and browser-neutral runtime metadata.",
                    href: "/articles/hydration"
                ),
            ]
        )
        .render()

        #expect(html.contains("<title>Latest Articles</title>"))
        #expect(html.contains("Typed HTML in Swift"))
        #expect(html.contains("style=\"max-width: 720px; margin: 0 auto; padding: 32px; font: 16px -apple-system, BlinkMacSystemFont, sans-serif\""))
    }

    @Test
    func statefulRuntimeSnippetInvokesClientHandler() throws {
        var runtime = try BrowserHydrationRuntime(
            root: DocumentationInlineCounter(),
            host: BrowserDOMCommandBuffer(),
            stateStore: StateStore()
        )

        let handler = try #require(runtime.session.artifact.clientHandlers.handlers.first)
        let update = try runtime.invoke(handlerID: handler.id)

        #expect(update.html.contains("Count 1"))
        #expect(runtime.host.lastBatch()?.isEmpty == false)
    }
}
