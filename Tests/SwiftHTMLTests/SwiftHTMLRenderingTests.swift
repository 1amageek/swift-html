import SwiftHTML
import Testing

private struct TestEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = "default"
}

private extension EnvironmentValues {
    var testValue: String {
        get { self[TestEnvironmentKey.self] }
        set { self[TestEnvironmentKey.self] = newValue }
    }
}

private struct EnvironmentReader: ClientComponent {
    @Environment(\.testValue) private var value: String

    @HTMLBuilder
    var body: some HTML {
        span(.id("environment-value")) {
            value
        }
    }
}

private struct ControlFlowDocument: Component {
    enum Mode {
        case list
        case detail
    }

    let showOptionalContent: Bool
    let mode: Mode

    @HTMLBuilder
    var body: some HTML {
        div {
            if showOptionalContent {
                span(.class("optional")) {
                    "optional"
                }
            }

            switch mode {
            case .list:
                ul {
                    for index in [1, 2, 3] {
                        li {
                            index
                        }
                    }
                }
            case .detail:
                p {
                    "detail"
                }
            }
        }
    }
}

private struct Row: Identifiable, Sendable {
    let id: Int
    let title: String
}

private struct TestAttributeTransformer: HTMLAttributeTransformer {
    func transform(_ attributes: [HTMLAttribute]) -> [HTMLAttribute] {
        var classTokens: [String] = []
        var remaining: [HTMLAttribute] = []

        for attribute in attributes {
            switch attribute.name {
            case "class":
                if let value = attribute.value {
                    classTokens.append(value)
                }
            case "style":
                if let style = attribute.style {
                    classTokens.append("style-\(style.declarations.count)")
                }
            default:
                remaining.append(attribute)
            }
        }

        return [.class(classTokens.joined(separator: " "))] + remaining
    }
}

@Suite
struct SwiftHTMLRenderingTests {
    @Test
    func rendersLowercaseDocumentAndEscapesText() {
        let artifact = HTMLRenderer().render(
            document {
                html {
                    head {
                        meta(.charset("utf-8"))
                        title { "Hello <World>" }
                    }
                    body {
                        div(.id("root"), .class("screen")) {
                            "5 > 3 & 2 < 4"
                        }
                    }
                }
            }
        )

        #expect(artifact.html.contains("<!doctype html><html>"))
        #expect(artifact.html.contains("<meta charset=\"utf-8\">"))
        #expect(artifact.html.contains("<title>Hello &lt;World&gt;</title>"))
        #expect(artifact.html.contains("<div id=\"root\" class=\"screen\">5 &gt; 3 &amp; 2 &lt; 4</div>"))
    }

    @Test
    func rendersTextInitializerShortcutsForContainerElements() {
        let rendered = section {
            h2("Client <Counter>")
            p(.class("lead"), text: "Owned by a ClientComponent & WASM.")
            Element("custom-label", text: "Plain <custom> text")
        }
        .render()

        #expect(rendered.contains("<h2>Client &lt;Counter&gt;</h2>"))
        #expect(rendered.contains("<p class=\"lead\">Owned by a ClientComponent &amp; WASM.</p>"))
        #expect(rendered.contains("<custom-label>Plain &lt;custom&gt; text</custom-label>"))
    }

    @Test
    func rendersTypedAttributesAndVoidElements() {
        let rendered = input(
            .type(InputType.email),
            .name("email"),
            .value("hello@example.com"),
            .required,
            .data("field", "email"),
            .aria("label", "Email"),
            .style(.minHeight("36px"))
        )
        .render()

        #expect(rendered == "<input type=\"email\" name=\"email\" value=\"hello@example.com\" required data-field=\"email\" aria-label=\"Email\" style=\"min-height: 36px\">")
    }

    @Test
    func rendersStyleBuilderDeclarations() {
        let shouldStretch = true
        let rendered = div {
            "Panel"
        }
        .style {
            .minHeight("36px")
            if shouldStretch {
                .width("100%")
            }
            .custom("--panel-tone", "muted")
        }
        .render()

        #expect(rendered.contains("style=\"min-height: 36px; width: 100%; --panel-tone: muted\""))
    }

    @Test
    func rendersConsecutiveStyleBuilderDeclarations() {
        let rendered = div {
            "Panel"
        }
        .style {
            .minHeight("36px")
            .width("100%")
            .custom("--panel-tone", "muted")
        }
        .render()

        #expect(rendered.contains("style=\"min-height: 36px; width: 100%; --panel-tone: muted\""))
    }

    @Test
    func attributeTransformContextTransformsTypedStyleAcrossRenderStack() {
        let rendered = HTMLAttributeTransformContext.withValue(TestAttributeTransformer()) {
            div(.class("panel"), .style(.minHeight("36px")), .id("card")) {
                "Panel"
            }
            .render()
        }

        #expect(rendered == "<div class=\"panel style-1\" id=\"card\">Panel</div>")
    }

    @Test
    func rendersGeneratedStandardStylePropertyHelpers() {
        let rendered = div {
            "Panel"
        }
        .style {
            .zIndex("10")
            .whiteSpace("nowrap")
            .insetInlineStart("2rem")
            .animationTimeline("view()")
            .containerType("inline-size")
            .textWrapStyle("balance")
        }
        .render()

        #expect(rendered.contains("z-index: 10"))
        #expect(rendered.contains("white-space: nowrap"))
        #expect(rendered.contains("inset-inline-start: 2rem"))
        #expect(rendered.contains("animation-timeline: view()"))
        #expect(rendered.contains("container-type: inline-size"))
        #expect(rendered.contains("text-wrap-style: balance"))
    }

    @Test
    func rendersStylesheetBuilderRules() {
        let includeHover = true
        let stylesheet = Stylesheet {
            rule(".panel") {
                .minHeight("36px")
                .width("100%")
                .custom("--panel-tone", "muted")
            }
            if includeHover {
                rule(".panel:hover") {
                    .background("var(--panel-hover)")
                }
            }
        }

        #expect(stylesheet.cssText.contains(".panel {"))
        #expect(stylesheet.cssText.contains("  min-height: 36px;"))
        #expect(stylesheet.cssText.contains("  width: 100%;"))
        #expect(stylesheet.cssText.contains("  --panel-tone: muted;"))
        #expect(stylesheet.cssText.contains(".panel:hover {"))
        #expect(stylesheet.cssText.contains("  background: var(--panel-hover);"))
    }

    @Test
    func rejectsInvalidNamesAndUnsafeURLAttributes() {
        let artifact = HTMLRenderer().render(
            div {
                Element("img src=x onerror=alert(1)", attributes: [])
                img(.srcset("javascript:alert(1) 1x"))
                link(.imagesrcset("javascript:alert(1) 1x"))
                a(.href("javascript:alert(1)"), .attribute("x onmouseover=alert(1)")) {
                    "bad"
                }
                a(.ping("javascript:alert(1)")) {
                    "ping"
                }
            }
        )

        #expect(!artifact.html.contains("onerror"))
        #expect(!artifact.html.contains("onmouseover"))
        #expect(!artifact.html.contains("javascript:"))
        let codes = artifact.errors.map { diagnostic in diagnostic.code }
        #expect(codes.contains(.invalidElementName))
        #expect(codes.contains(.invalidAttributeName))
        #expect(codes.contains(.unsafeURLAttribute))
    }

    @Test
    func imageSourcesAcceptDataImageURLs() {
        let pixel = "data:image/png;base64,iVBORw0KGgo="
        let svg = "data:image/svg+xml;base64,PHN2Zy8+"
        let artifact = HTMLRenderer().render(
            div {
                img(.src(pixel))
                img(.srcset("\(svg) 2x"))
                picture {
                    source(.srcset("\(svg) 1x"))
                    img(.src(pixel))
                }
                link(.rel("preload"), .imagesrcset("\(svg) 1x"))
                video(.poster(pixel)) {}
            }
        )

        #expect(artifact.html.contains("src=\"\(pixel)\""))
        #expect(artifact.html.contains("srcset=\"\(svg) 2x\""))
        #expect(artifact.html.contains("srcset=\"\(svg) 1x\""))
        #expect(artifact.html.contains("imagesrcset=\"\(svg) 1x\""))
        #expect(artifact.html.contains("poster=\"\(pixel)\""))
        #expect(artifact.errors.isEmpty)
    }

    @Test
    func nonImagePositionsStillRejectDataURLs() {
        let artifact = HTMLRenderer().render(
            div {
                a(.href("data:text/html,<script>alert(1)</script>")) {
                    "bad link"
                }
                img(.src("data:text/html,<script>alert(1)</script>"))
                script(.src("data:image/png;base64,iVBORw0KGgo=")) {}
                iframe(.src("data:image/svg+xml;base64,PHN2Zy8+")) {}
            }
        )

        #expect(!artifact.html.contains("data:"))
        let codes = artifact.errors.map { diagnostic in diagnostic.code }
        #expect(codes.filter { $0 == .unsafeURLAttribute }.count == 4)
    }

    @Test
    func srcsetDataImageURLsDoNotMaskUnsafeCandidates() {
        let svg = "data:image/svg+xml;base64,PHN2Zy8+"
        let artifact = HTMLRenderer().render(
            div {
                img(.srcset("\(svg) 1x, javascript:alert(1) 2x"))
                img(.srcset("data:image/svg+xml;base64,PHN2 Zy8+ 1x"))
            }
        )

        #expect(!artifact.html.contains("srcset="))
        let codes = artifact.errors.map { diagnostic in diagnostic.code }
        #expect(codes.filter { $0 == .unsafeURLAttribute }.count == 2)
    }

    @Test
    func dataImageURLsRequireImageMediaTypeAndBase64Payload() {
        let artifact = HTMLRenderer().render(
            div {
                img(.src("data:text/html;base64,PHNjcmlwdD48L3NjcmlwdD4="))
                img(.src("data:image/svg+xml,%3Csvg%2F%3E"))
                img(.src("data:image/png;base64,"))
            }
        )

        #expect(!artifact.html.contains("data:"))
        let codes = artifact.errors.map { diagnostic in diagnostic.code }
        #expect(codes.filter { $0 == .unsafeURLAttribute }.count == 3)
    }

    @Test
    func srcdocRequiresRawHTMLForEmbeddedMarkup() {
        let escaped = iframe(.srcdoc("<script>alert(1)</script>")) {}.render()
        let raw = iframe(.srcdoc(rawHTML("<p>Allowed</p>"))) {}.render()

        #expect(escaped.contains("srcdoc=\"&amp;lt;script&amp;gt;alert(1)&amp;lt;/script&amp;gt;\""))
        #expect(raw.contains("srcdoc=\"&lt;p&gt;Allowed&lt;/p&gt;\""))
    }

    @Test
    func rawTextElementsDoNotEscapeTextAsHTML() {
        let rendered = script {
            "if (a < b) { window.ready = true; }"
        }
        .render()

        #expect(rendered == "<script>if (a < b) { window.ready = true; }</script>")
    }

    @Test
    func builderUsesTupleComponentForMultipleChildren() {
        let built = makeHTML {
            span { "One" }
            strong { "Two" }
        }

        #expect(String(reflecting: type(of: built)).contains("TupleComponent"))
        #expect(built.render() == "<span>One</span><strong>Two</strong>")
    }

    @Test
    func recordsEventBindingsInRenderArtifact() {
        let artifact = HTMLRenderer().render(
            ClientButton()
        )

        #expect(artifact.html.contains("data-event-click=\"h1\""))
        #expect(artifact.clientHandlers.handlers.count == 1)
        #expect(artifact.clientHandlers.handlers[0].id == HandlerID("h1"))
        #expect(artifact.clientHandlers.handlers[0].eventName == "click")
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func browserHydrationMarkersAreOptIn() {
        let content = div {
            button(.type(ButtonType.button)) {
                "Tap"
            }
        }
        let plain = HTMLRenderer().render(content)
        let marked = HTMLRenderer().render(
            content,
            options: .development.withBrowserHydrationMarkers()
        )

        #expect(!plain.html.contains("data-node"))
        #expect(marked.html.contains("data-node=\""))
        #expect(marked.html.contains("<button data-node=\""))
    }

    @Test
    func readsEnvironmentThroughComponentBody() {
        let rendered = EnvironmentReader()
            .environment(\.testValue, "configured")
            .render()

        #expect(rendered.contains("<span id=\"environment-value\">configured</span>"))
        #expect(rendered.contains("component:"))
    }

    @Test
    func supportsIfSwitchAndForInBuilder() {
        let list = ControlFlowDocument(showOptionalContent: true, mode: .list).render()
        let detail = ControlFlowDocument(showOptionalContent: false, mode: .detail).render()

        #expect(list.contains("<span class=\"optional\">optional</span>"))
        #expect(list.contains("<ul><li>1</li><li>2</li><li>3</li></ul>"))
        #expect(detail.contains("<p>detail</p>"))
        #expect(!detail.contains("optional"))
    }

    @Test
    func storesForEachKeysAndProducesDiffOperations() {
        let oldArtifact = HTMLRenderer().render(rows([1, 2]))
        let newArtifact = HTMLRenderer().render(rows([2, 1, 3]))

        let keys = oldArtifact.nodeKeys.map(\.rawValue)
        #expect(keys.contains("1"))
        #expect(keys.contains("2"))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)
        #expect(patches.contains { patch in
            if case .moveKeyed = patch.operation {
                return true
            }
            return false
        })
        #expect(patches.contains { patch in
            if case .insertSubtree = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func runtimeMarkerContractNamesHydrationAttributesAndBoundaries() {
        #expect(HTMLRuntimeMarkers.nodeAttribute == "data-node")
        #expect(HTMLRuntimeMarkers.keyAttribute == "data-key")
        #expect(HTMLRuntimeMarkers.eventAttribute("click") == "data-event-click")
        #expect(HTMLRuntimeMarkers.componentCommentValue(ComponentID("c1"), edge: .begin) == "component:c1:begin")
        #expect(HTMLRuntimeMarkers.serverSlotCommentValue(ServerSlotID("s1"), edge: .end) == "server-slot:s1:end")
    }

    @Test(.timeLimit(.minutes(1)))
    func rendersLargeGraphsWithinPerformanceBudget() {
        let values = Array(0..<5_000)
        let clock = ContinuousClock()
        let start = clock.now
        let artifact = HTMLRenderer().render(
            table {
                tbody {
                    ForEach(values, id: { value in value }) { value in
                        tr {
                            td { value }
                            td { "Row \(value)" }
                        }
                    }
                }
            }
        )
        let elapsed = start.duration(to: clock.now)

        #expect(artifact.html.contains("Row 4999"))
        #expect(artifact.nodeCount > 15_000)
        #expect(elapsed < .seconds(10))
    }

    private func rows(_ ids: [Int]) -> some HTML {
        ul {
            ForEach(ids.map { Row(id: $0, title: "Row \($0)") }) { row in
                li {
                    row.title
                }
            }
        }
    }

    private func makeHTML(@HTMLBuilder _ content: () -> some HTML) -> some HTML {
        content()
    }
}

private struct ClientButton: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {}) {
            "Run"
        }
    }
}
