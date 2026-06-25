import SwiftHTML
import Synchronization
import Testing

private struct PatternEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = "default"
}

private extension EnvironmentValues {
    var patternValue: String {
        get { self[PatternEnvironmentKey.self] }
        set { self[PatternEnvironmentKey.self] = newValue }
    }
}

private struct PatternEnvironmentReader: ClientComponent {
    @Environment(PatternEnvironmentKey.self) private var value: String

    @HTMLBuilder
    var body: some HTML {
        span(.class("environment-value")) {
            value
        }
    }
}

private struct NestedPatternComponent: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        div(.id("nested-component")) {
            PatternEnvironmentReader()
        }
    }
}

@Suite
struct SwiftHTMLPatternTests {
    @Test
    func rendersEmptyCommentRawHTMLAndCustomElements() {
        #expect(makeHTML {}.render() == "")
        #expect(EmptyHTML().render() == "")
        #expect(comment("a < b & c").render() == "<!--a &lt; b &amp; c-->")
        #expect(script { rawHTML("if (a < b) { window.ready = true; }") }.render() == "<script>if (a < b) { window.ready = true; }</script>")

        let rendered = Element("swift-widget", .data("state", "ready")) {
            span { "slot" }
        }
        .render()

        #expect(rendered == "<swift-widget data-state=\"ready\"><span>slot</span></swift-widget>")
    }

    @Test
    func escapesAttributeValuesIndependentlyFromTextValues() {
        let rendered = a(
            .href("/search?q=a&b=<c>"),
            .title("\"quote\" and 'single'")
        ) {
            "5 > 3 & 2 < 4"
        }
        .render()

        #expect(rendered == "<a href=\"/search?q=a&amp;b=&lt;c&gt;\" title=\"&quot;quote&quot; and &#39;single&#39;\">5 &gt; 3 &amp; 2 &lt; 4</a>")
    }

    @Test
    func escapesSrcdocTextAndRawHTMLDeliberately() {
        let escapedText = iframe(.srcdoc("<p>safe text</p>")).render()
        let rawMarkup = iframe(.srcdoc(rawHTML("<p title=\"quoted\">raw</p>"))).render()

        #expect(escapedText == "<iframe srcdoc=\"&amp;lt;p&amp;gt;safe text&amp;lt;/p&amp;gt;\"></iframe>")
        #expect(rawMarkup == "<iframe srcdoc=\"&lt;p title=&quot;quoted&quot;&gt;raw&lt;/p&gt;\"></iframe>")
    }

    @Test
    func supportsPrimitiveBuilderExpressions() {
        let rendered = div {
            42
            1.25
            true
            false
        }
        .render()

        #expect(rendered == "<div>421.25truefalse</div>")
    }

    @Test
    func supportsFluentElementModifiers() {
        let rendered = button {
            "Save"
        }
        .id("save")
        .class("primary")
        .hidden(false)
        .disabled(true)
        .data("action", "save")
        .aria("label", "Save")
        .render()

        #expect(rendered == "<button id=\"save\" class=\"primary\" disabled data-action=\"save\" aria-label=\"Save\">Save</button>")
    }

    @Test
    func recordsAndInvokesEventHandlersFromAttributesAndModifiers() {
        let counter = CounterBox()
        let artifact = EventPanel(counter: counter).renderArtifact()

        #expect(artifact.clientHandlers.handlers.map(\.id.rawValue) == ["h1", "h2", "h3", "h4"])
        #expect(artifact.clientHandlers.handlers.map(\.eventName) == ["input", "change", "click", "custom"])
        #expect(artifact.html.contains("data-event-input=\"h1\""))
        #expect(artifact.html.contains("data-event-custom=\"h4\""))

        artifact.clientHandlers.handlers[0].invoke(with: DOMEvent(value: "typed"))
        artifact.clientHandlers.handlers[1].invoke()
        artifact.clientHandlers.handlers[2].invoke()
        artifact.clientHandlers.handlers[3].invoke()

        #expect(counter.value() == 1_111)
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func eventPayloadCarriesKeyboardPointerAndMetadataValues() throws {
        let payload = EventPayloadBox()
        let artifact = PayloadEventPanel(payload: payload).renderArtifact()

        #expect(artifact.clientHandlers.handlers.map(\.eventName) == ["click", "keydown"])

        let click = try #require(artifact.clientHandlers.handlers.first { handler in
            handler.eventName == "click"
        })
        click.invoke(with: DOMEvent(clientX: 12.5, clientY: 24.25, metadata: ["target": "menu"]))

        let keydown = try #require(artifact.clientHandlers.handlers.first { handler in
            handler.eventName == "keydown"
        })
        keydown.invoke(with: DOMEvent(key: "Enter", code: "Enter", inputType: "insertLineBreak"))

        #expect(payload.snapshot() == "click:12.5:24.25:menu|key:Enter:Enter:insertLineBreak")
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func restoresScopedEnvironmentAfterNestedOverride() {
        let rendered = div {
            PatternEnvironmentReader()
            PatternEnvironmentReader()
                .environment(PatternEnvironmentKey.self, "child")
            NestedPatternComponent()
        }
        .environment(PatternEnvironmentKey.self, "parent")
        .render()

        #expect(rendered.contains("<span class=\"environment-value\">child</span>"))
        #expect(rendered.contains("<div id=\"nested-component\">"))
        #expect(rendered.components(separatedBy: "<span class=\"environment-value\">parent</span>").count - 1 == 2)
    }

    @Test
    func recordsHydrationComponentsForNestedComponents() {
        let artifact = div {
            NestedPatternComponent()
            PatternEnvironmentReader()
        }
        .renderArtifact()

        let componentNames = artifact.hydration.components.map(\.typeName)

        #expect(componentNames.contains { $0.hasSuffix(".NestedPatternComponent") })
        #expect(componentNames.contains { $0.hasSuffix(".PatternEnvironmentReader") })
        #expect(componentNames.count == 3)
        #expect(artifact.hydration.componentIDs.count == 3)
    }

    @Test
    func rendersRepresentativeTypedAttributes() {
        let rendered = form(
            .method(.post),
            .action("/submit"),
            .acceptCharset("utf-8"),
            .autocomplete("off"),
            .novalidate
        ) {
            input(
                .type(.email),
                .name("email"),
                .placeholder("hello@example.com"),
                .inputmode("email"),
                .enterkeyhint("send"),
                .required
            )
            button(
                .type(ButtonType.submit),
                .formaction("/confirm"),
                .formmethod(.post),
                .formenctype("multipart/form-data"),
                .formtarget(.self),
                .formnovalidate
            ) {
                "Submit"
            }
        }
        .render()

        #expect(rendered.contains("accept-charset=\"utf-8\""))
        #expect(rendered.contains("inputmode=\"email\""))
        #expect(rendered.contains("enterkeyhint=\"send\""))
        #expect(rendered.contains("formenctype=\"multipart/form-data\""))
        #expect(rendered.contains("formnovalidate"))
    }

    @Test
    func rendersPlatformAndInputHintAttributesFromSpecification() {
        let rendered = div(
            .slot("content"),
            .part("button icon"),
            .exportparts("button: host-button"),
            .is("expanding-panel")
        ) {
            link(.rel("modulepreload"), .href("/app.wasm"), .blocking("render"))
            dialog(.open, .closedby("closerequest")) {
                input(
                    .type(.text),
                    .autocapitalize("words"),
                    .autocorrect("off"),
                    .virtualkeyboardpolicy("manual"),
                    .writingsuggestions("false")
                )
            }
        }
        .render()

        #expect(rendered.contains("exportparts=\"button: host-button\""))
        #expect(rendered.contains("is=\"expanding-panel\""))
        #expect(rendered.contains("blocking=\"render\""))
        #expect(rendered.contains("closedby=\"closerequest\""))
        #expect(rendered.contains("autocapitalize=\"words\""))
        #expect(rendered.contains("autocorrect=\"off\""))
        #expect(rendered.contains("virtualkeyboardpolicy=\"manual\""))
        #expect(rendered.contains("writingsuggestions=\"false\""))
    }

    @Test
    func rendersTypedEnumeratedAttributes() {
        let rendered = div {
            img(
                .src("/hero.png"),
                .alt("Hero"),
                .crossorigin(CrossOrigin.useCredentials),
                .referrerpolicy(ReferrerPolicy.strictOriginWhenCrossOrigin),
                .fetchpriority(FetchPriority.high),
                .loading(Loading.lazy),
                .decoding(Decoding.async)
            )
            input(
                .type(InputType.search),
                .inputmode(InputMode.search),
                .enterkeyhint(EnterKeyHint.search),
                .autocapitalize(Autocapitalize.none),
                .autocorrect(Autocorrect.off),
                .virtualkeyboardpolicy(VirtualKeyboardPolicy.manual),
                .writingsuggestions(WritingSuggestions.disabled)
            )
            th(.scope(TableScope.col)) {
                "Name"
            }
            textarea(.wrap(TextareaWrap.hard)) {
                "Notes"
            }
            video(.preload(Preload.metadata)) {
                track(.kind(TrackKind.captions), .srclang("en"), .label("English"))
            }
            button(.popovertarget("menu"), .popovertargetaction(PopoverTargetAction.toggle)) {
                "Menu"
            }
            dialog(.closedby(DialogClosedBy.closeRequest)) {
                "Dialog"
            }
        }
        .render()

        #expect(rendered.contains("crossorigin=\"use-credentials\""))
        #expect(rendered.contains("referrerpolicy=\"strict-origin-when-cross-origin\""))
        #expect(rendered.contains("fetchpriority=\"high\""))
        #expect(rendered.contains("decoding=\"async\""))
        #expect(rendered.contains("inputmode=\"search\""))
        #expect(rendered.contains("enterkeyhint=\"search\""))
        #expect(rendered.contains("autocapitalize=\"none\""))
        #expect(rendered.contains("virtualkeyboardpolicy=\"manual\""))
        #expect(rendered.contains("writingsuggestions=\"false\""))
        #expect(rendered.contains("scope=\"col\""))
        #expect(rendered.contains("wrap=\"hard\""))
        #expect(rendered.contains("preload=\"metadata\""))
        #expect(rendered.contains("kind=\"captions\""))
        #expect(rendered.contains("popovertargetaction=\"toggle\""))
        #expect(rendered.contains("closedby=\"closerequest\""))
    }

    private func makeHTML(@HTMLBuilder _ content: () -> some HTML) -> some HTML {
        content()
    }
}

private struct EventPanel: ClientComponent {
    let counter: CounterBox

    @HTMLBuilder
    var body: some HTML {
        div {
            input(
                .onInput { event in
                    if event.value == "typed" {
                        counter.increment(by: 1)
                    }
                },
                .onChange { _ in
                    counter.increment(by: 10)
                }
            )
            button {
                "Run"
            }
            .onClick {
                counter.increment(by: 100)
            }
            .on("custom") { _ in
                counter.increment(by: 1_000)
            }
        }
    }
}

private struct PayloadEventPanel: ClientComponent {
    let payload: EventPayloadBox

    @HTMLBuilder
    var body: some HTML {
        div {
            button(.onClick { event in
                payload.append("click:\(event.clientX ?? -1):\(event.clientY ?? -1):\(event["target"] ?? "missing")")
            }) {
                "Payload"
            }
            input(.onKeyDown { event in
                payload.append("key:\(event.key ?? "missing"):\(event.code ?? "missing"):\(event.inputType ?? "missing")")
            })
        }
    }
}

private final class CounterBox: Sendable {
    private let storage = Mutex(0)

    func increment(by amount: Int) {
        storage.withLock { value in
            value += amount
        }
    }

    func value() -> Int {
        storage.withLock { value in
            value
        }
    }
}

private final class EventPayloadBox: Sendable {
    private let storage = Mutex([String]())

    func append(_ value: String) {
        storage.withLock { values in
            values.append(value)
        }
    }

    func snapshot() -> String {
        storage.withLock { values in
            values.joined(separator: "|")
        }
    }
}
