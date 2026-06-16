@testable import SwiftHTML
import Testing

@Suite(.serialized)
struct SwiftHTMLPerformanceTests {
    @Test(.timeLimit(.minutes(1)))
    func rendersLargeTablesWithinLinearGraphBudget() {
        for size in [1_000, 3_000, 6_000] {
            let artifact = timed("render table \(size)", limit: .seconds(10)) {
                HTMLRenderer().render(largeTable(rowCount: size))
            }

            #expect(artifact.html.contains("Row \(size - 1)"))
            #expect(artifact.nodeCount == 3 + size * 6)
            #expect(artifact.stringCount <= size * 2 + 8)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func diffsLargeKeyedAppendWithinBudget() {
        let size = 6_000
        let oldArtifact = HTMLRenderer().render(keyedRows(Array(0..<size)))
        let newArtifact = HTMLRenderer().render(keyedRows(Array(0...size)))

        let patches = timed("diff keyed append \(size)", limit: .seconds(8)) {
            HTMLDiffer().diff(from: oldArtifact, to: newArtifact)
        }

        #expect(patches.count == 1)
        #expect(patches.contains { patch in
            if case .insertSubtree(parent: _, index: size, html: _) = patch.operation {
                return true
            }
            return false
        })
    }

    @Test(.timeLimit(.minutes(1)))
    func diffsLargeKeyedReorderWithoutTextChurn() {
        let size = 3_000
        let oldArtifact = HTMLRenderer().render(keyedRows(Array(0..<size)))
        let newOrder = [size - 1] + Array(0..<(size - 1))
        let newArtifact = HTMLRenderer().render(keyedRows(newOrder))

        let patches = timed("diff keyed reorder \(size)", limit: .seconds(10)) {
            HTMLDiffer().diff(from: oldArtifact, to: newArtifact)
        }

        #expect(patches.count == size)
        #expect(!patches.contains { patch in
            if case .updateText = patch.operation {
                return true
            }
            return false
        })
    }

    @Test(.timeLimit(.minutes(1)))
    func rendersHandlerHeavyDOMWithinBudget() {
        let size = 3_000
        let artifact = timed("render handlers \(size)", limit: .seconds(8)) {
            HTMLRenderer().render(handlerHeavyDOM(count: size))
        }

        #expect(artifact.clientHandlers.handlers.count == size)
        #expect(artifact.clientHandlers.handlers.first?.id.rawValue == "h1")
        #expect(artifact.clientHandlers.handlers.last?.id.rawValue == "h\(size)")
    }

    @Test(.timeLimit(.minutes(1)))
    func rendersManyClientEnvironmentSnapshotsWithinBudget() {
        let size = 2_000
        let artifact = timed("render environment snapshots \(size)", limit: .seconds(8)) {
            HTMLRenderer().render(
                environmentHeavyDOM(count: size)
                    .environment(\.performanceValue, "snapshot")
            )
        }

        #expect(artifact.hydration.components.count == size)
        #expect(artifact.hydration.components.allSatisfy { component in
            component.environmentSnapshot.values.count == 1
        })
        #expect(artifact.errors.isEmpty)
        #expect(artifact.html.contains("Row 1999: snapshot"))
    }

    @Test(.timeLimit(.minutes(1)))
    func rendersManyTextareaBindingsWithinBudget() {
        let size = 2_000
        let artifact = timed("render textarea bindings \(size)", limit: .seconds(8)) {
            HTMLRenderer().render(textareaHeavyDOM(count: size))
        }

        #expect(artifact.hydration.components.count == size)
        #expect(artifact.attributeRecords.contains { attribute in
            attribute.name == "value"
                && attribute.value == "Note 1999 <draft>"
                && attribute.kind == .propertyBinding
        })
        #expect(!artifact.html.contains("value=\"Note"))
        #expect(artifact.html.contains("<textarea>Note 1999 &lt;draft&gt;</textarea>"))
    }

    @Test(.timeLimit(.minutes(1)))
    func escapesLargeTextAndAttributeValuesWithinBudget() {
        let repeated = String(repeating: "&<>\"'", count: 10_000)

        let rendered = timed("escape large values", limit: .seconds(5)) {
            div(.title(repeated)) {
                repeated
            }
            .render()
        }

        #expect(rendered.contains("&amp;&lt;&gt;&quot;&#39;"))
        #expect(rendered.contains("&amp;&lt;&gt;\"'"))
    }

    @Test(.timeLimit(.minutes(1)))
    func rendersDeepNestingWithinBudget() {
        let depth = 100

        let artifact = timed("render deep nesting \(depth)", limit: .seconds(10)) {
            HTMLRenderer().render(nestedDiv(depth: depth))
        }

        #expect(artifact.nodeCount == depth + 2)
        #expect(artifact.html.hasPrefix("<div><div>"))
        #expect(artifact.html.hasSuffix("</div></div>"))
    }

    private func timed<Result>(_ label: String, limit: Duration, operation: () -> Result) -> Result {
        let clock = ContinuousClock()
        let start = clock.now
        let result = operation()
        let elapsed = start.duration(to: clock.now)
        print("\(label): \(elapsed)")
        #expect(elapsed < limit)
        return result
    }

    private func largeTable(rowCount: Int) -> some HTML {
        table {
            tbody {
                ForEach(Array(0..<rowCount), id: { value in value }) { value in
                    tr {
                        td { value }
                        td { "Row \(value)" }
                    }
                }
            }
        }
    }

    private func keyedRows(_ values: [Int]) -> some HTML {
        ul {
            ForEach(values, id: { value in value }) { value in
                li {
                    "Row \(value)"
                }
            }
        }
    }

    private func handlerHeavyDOM(count: Int) -> some HTML {
        HandlerHeavyDOM(values: Array(0..<count))
    }

    private func environmentHeavyDOM(count: Int) -> some HTML {
        EnvironmentHeavyDOM(values: Array(0..<count))
    }

    private func textareaHeavyDOM(count: Int) -> some HTML {
        TextareaHeavyDOM(values: Array(0..<count))
    }

    private func nestedDiv(depth: Int) -> some HTML {
        NestedDiv(depth: depth)
    }
}

private struct NestedDiv: HTMLPrimitive {
    let depth: Int

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        let text = builder.addNode(kind: .text(builder.intern("leaf")), children: [])
        var current = builder.addNode(kind: .element(builder.intern("span")), children: [text])

        for _ in 0..<depth {
            current = builder.addNode(kind: .element(builder.intern("div")), children: [current])
        }

        return current
    }
}

private struct PerformanceEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = "default"
}

private extension EnvironmentValues {
    var performanceValue: String {
        get { self[PerformanceEnvironmentKey.self] }
        set { self[PerformanceEnvironmentKey.self] = newValue }
    }
}

private struct HandlerHeavyDOM: ClientComponent {
    let values: [Int]

    @HTMLBuilder
    var body: some HTML {
        div {
            ForEach(values, id: { value in value }) { value in
                button(.type(ButtonType.button), .onClick({})) {
                    "Button \(value)"
                }
            }
        }
    }
}

private struct EnvironmentHeavyDOM: Component {
    let values: [Int]

    @HTMLBuilder
    var body: some HTML {
        div {
            ForEach(values, id: { value in value }) { value in
                EnvironmentHeavyRow(value: value)
            }
        }
    }
}

private struct EnvironmentHeavyRow: ClientComponent {
    let value: Int
    @Environment(\.performanceValue) private var environmentValue: String

    @HTMLBuilder
    var body: some HTML {
        span(.data("row", String(value))) {
            "Row \(value): \(environmentValue)"
        }
    }
}

private struct TextareaHeavyDOM: Component {
    let values: [Int]

    @HTMLBuilder
    var body: some HTML {
        div {
            ForEach(values, id: { value in value }) { value in
                TextareaHeavyRow(value: value)
            }
        }
    }
}

private struct TextareaHeavyRow: ClientComponent {
    let value: Int
    @State private var note: String

    init(value: Int) {
        self.value = value
        self._note = State(wrappedValue: "Note \(value) <draft>")
    }

    @HTMLBuilder
    var body: some HTML {
        textarea(.value($note)) {}
    }
}
