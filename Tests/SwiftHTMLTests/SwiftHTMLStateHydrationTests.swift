import SwiftHTML
import Testing

private struct HydrationEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = "default"
}

private extension EnvironmentValues {
    var hydrationValue: String {
        get { self[HydrationEnvironmentKey.self] }
        set { self[HydrationEnvironmentKey.self] = newValue }
    }
}

private struct CounterComponent: ClientComponent, Sendable {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Count \(count)"
        }
    }
}

private struct EnvironmentConsumerComponent: ClientComponent {
    @Environment(\.hydrationValue) private var value: String

    @HTMLBuilder
    var body: some HTML {
        span(.class("hydration-value")) {
            value
        }
    }
}

private struct StatefulRowComponent: ClientComponent, Sendable {
    let id: Int
    @State private var taps = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            taps += 1
        }) {
            "Row \(id): \(taps)"
        }
    }
}

private struct TextInputComponent: ClientComponent, Sendable {
    @State private var name = "Alice"

    @HTMLBuilder
    var body: some HTML {
        input(
            .type(InputType.text),
            .value($name),
            .onInput { event in
                name = event.value ?? ""
            }
        )
    }
}

private struct CheckboxComponent: ClientComponent, Sendable {
    @State private var accepted = false

    @HTMLBuilder
    var body: some HTML {
        input(
            .type(InputType.checkbox),
            .checked($accepted),
            .onChange { event in
                accepted = event.checked ?? false
            }
        )
    }
}

private struct TextareaComponent: ClientComponent, Sendable {
    @State private var notes = "Line <one>"

    @HTMLBuilder
    var body: some HTML {
        textarea(
            .value($notes),
            .onInput { event in
                notes = event.value ?? ""
            }
        ) {
            "fallback"
        }
    }
}

// A plain (non-client) child that renders the mutating handler for a binding it
// receives from its owner. Nested inside a ClientComponent it is client-owned but
// still gets its own componentID, so it reproduces the cross-component case where
// the handler is rendered by a different component than the @State owner.
private struct BindingChildComponent: Component {
    let value: Binding<Int>

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            value.wrappedValue += 1
        }) {
            "Child \(value.wrappedValue)"
        }
    }
}

private struct BindingOwnerComponent: ClientComponent, Sendable {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        div {
            span(.class("owner-readout")) {
                "Owner \(count)"
            }
            BindingChildComponent(value: $count)
        }
    }
}

@Suite
struct SwiftHTMLStateHydrationTests {
    @Test
    func stateSlotsAreRecordedInHydrationManifest() throws {
        let store = StateStore()
        let artifact = CounterComponent().renderArtifact(stateStore: store)

        let component = try #require(artifact.hydration.components.first)
        let stateSlot = try #require(component.stateSlots.first)

        #expect(component.typeName.hasSuffix(".CounterComponent"))
        #expect(component.path == "root")
        #expect(component.id == stateSlot.componentID)
        #expect(stateSlot.valueType == "Swift.Int")
        #expect(artifact.html.contains("<!--swift-html-component:\(component.id.rawValue):begin-->"))
        #expect(artifact.html.contains("Count 0"))
    }

    @Test
    func eventHandlerMutatesComponentStateStore() throws {
        let store = StateStore()
        let first = CounterComponent().renderArtifact(stateStore: store)
        let component = try #require(first.hydration.components.first)
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(handler.componentID == component.id)
        #expect(store.dirtyComponents().isEmpty)

        handler.invoke()

        #expect(store.dirtyComponents() == [component.id])

        let second = CounterComponent().renderArtifact(stateStore: store)
        let secondComponent = try #require(second.hydration.components.first)

        #expect(secondComponent.id == component.id)
        #expect(second.html.contains("Count 1"))
    }

    @Test
    func environmentModifierSuppliesScopedContextWithoutHydrationBoundary() {
        let artifact = div {
            EnvironmentConsumerComponent()
            Group {
                EnvironmentConsumerComponent()
            }
            .environment(\.hydrationValue, "provided")
            EnvironmentConsumerComponent()
        }
        .environment(\.hydrationValue, "outer")
        .renderArtifact()

        #expect(artifact.html.components(separatedBy: "<span class=\"hydration-value\">outer</span>").count - 1 == 2)
        #expect(artifact.html.components(separatedBy: "<span class=\"hydration-value\">provided</span>").count - 1 == 1)
        #expect(artifact.hydration.components.count == 3)
        #expect(artifact.hydration.components.allSatisfy { !$0.environmentSnapshot.values.isEmpty })
        #expect(!artifact.hydration.components.contains { $0.typeName.contains("EnvironmentModifier") })
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func keyedForEachPreservesStateIdentityAcrossReorder() throws {
        let store = StateStore()
        let first = rows([1, 2]).renderArtifact(stateStore: store)
        let rowOne = try #require(component(forKey: 1, in: first))
        let rowTwo = try #require(component(forKey: 2, in: first))
        let rowOneHandler = try #require(first.clientHandlers.handlers.first { handler in
            handler.componentID == rowOne.id
        })

        rowOneHandler.invoke()

        let second = rows([2, 1]).renderArtifact(stateStore: store)
        let reorderedRowOne = try #require(component(forKey: 1, in: second))
        let reorderedRowTwo = try #require(component(forKey: 2, in: second))

        #expect(reorderedRowOne.id == rowOne.id)
        #expect(reorderedRowTwo.id == rowTwo.id)
        #expect(second.html.contains("Row 1: 1"))
        #expect(second.html.contains("Row 2: 0"))
    }

    @Test
    func bindingPassedToChildMutatesOwnerStateNotChildPhantomSlot() throws {
        let store = StateStore()
        let first = BindingOwnerComponent().renderArtifact(stateStore: store)
        let owner = try #require(first.hydration.components.first { component in
            component.typeName.hasSuffix(".BindingOwnerComponent")
        })
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(first.html.contains("Owner 0"))
        #expect(first.html.contains("Child 0"))
        #expect(store.dirtyComponents().isEmpty)

        handler.invoke()

        // The child rendered the handler, but the binding was projected by the
        // owner. The write must land in the owner's slot and mark the OWNER dirty,
        // not a per-child phantom slot. Re-rendering then reflects the new value in
        // both the owner's own readout and the child reading through the binding.
        #expect(store.dirtyComponents() == [owner.id])

        let second = BindingOwnerComponent().renderArtifact(stateStore: store)
        #expect(second.hydration.components.first { component in
            component.typeName.hasSuffix(".BindingOwnerComponent")
        }?.id == owner.id)
        #expect(second.html.contains("Owner 1"))
        #expect(second.html.contains("Child 1"))
    }

    @Test
    func bindingAttributeUsesStateValueAndEventMutation() throws {
        let store = StateStore()
        let first = TextInputComponent().renderArtifact(stateStore: store)
        let component = try #require(first.hydration.components.first)
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(first.html.contains("value=\"Alice\""))
        #expect(first.attributeRecords.contains { attribute in
            attribute.name == "value"
                && attribute.value == "Alice"
                && attribute.kind == .propertyBinding
        })
        #expect(handler.componentID == component.id)

        handler.invoke(with: DOMEvent(value: "Bob"))

        let second = TextInputComponent().renderArtifact(stateStore: store)

        #expect(second.hydration.components.first?.id == component.id)
        #expect(second.html.contains("value=\"Bob\""))
    }

    @Test
    func booleanBindingAttributeUsesStateValueAndEventMutation() throws {
        let store = StateStore()
        let first = CheckboxComponent().renderArtifact(stateStore: store)
        let component = try #require(first.hydration.components.first)
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(!first.html.contains(" checked"))
        #expect(first.attributeRecords.contains { attribute in
            attribute.name == "checked"
                && attribute.value == "false"
                && attribute.kind == .propertyBinding
        })
        #expect(handler.componentID == component.id)

        handler.invoke(with: DOMEvent(checked: true))

        let second = CheckboxComponent().renderArtifact(stateStore: store)

        #expect(second.hydration.components.first?.id == component.id)
        #expect(second.html.contains(" checked"))
        #expect(second.attributeRecords.contains { attribute in
            attribute.name == "checked"
                && attribute.value == "true"
                && attribute.kind == .propertyBinding
        })
    }

    @Test
    func textareaBindingRendersInitialTextAndUsesEventMutation() throws {
        let store = StateStore()
        let first = TextareaComponent().renderArtifact(stateStore: store)
        let component = try #require(first.hydration.components.first)
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(first.html.contains("<textarea data-swift-event-input=\"h1\">Line &lt;one&gt;</textarea>"))
        #expect(!first.html.contains("value=\""))
        #expect(!first.html.contains("fallback"))
        #expect(first.attributeRecords.contains { attribute in
            attribute.name == "value"
                && attribute.value == "Line <one>"
                && attribute.kind == .propertyBinding
        })
        #expect(handler.componentID == component.id)

        handler.invoke(with: DOMEvent(value: "Updated & saved"))

        let second = TextareaComponent().renderArtifact(stateStore: store)

        #expect(second.hydration.components.first?.id == component.id)
        #expect(second.html.contains("<textarea data-swift-event-input=\"h1\">Updated &amp; saved</textarea>"))
    }

    private func rows(_ ids: [Int]) -> some HTML {
        ul {
            ForEach(ids, id: { id in id }) { id in
                StatefulRowComponent(id: id)
            }
        }
    }

    private func component(forKey key: Int, in artifact: RenderArtifact) -> HydrationComponentRecord? {
        artifact.hydration.components.first { component in
            component.typeName.hasSuffix(".StatefulRowComponent")
                && component.path.contains("key:Swift.Int:\(key)")
        }
    }
}
