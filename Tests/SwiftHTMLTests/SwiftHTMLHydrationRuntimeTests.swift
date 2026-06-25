import Foundation
import SwiftHTML
import Testing

private struct RuntimeCounterComponent: ClientComponent, Sendable {
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

private struct RuntimeBidirectionalCounterComponent: ClientComponent, Sendable {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count -= 1
        }) {
            "Decrement"
        }
        output {
            "Client value \(count)"
        }
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Increment"
        }
    }
}

private struct RuntimeTextInputComponent: ClientComponent, Sendable {
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

private struct RuntimeReorderingComponent: ClientComponent, Sendable {
    @State private var reversed = false

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            reversed.toggle()
        }) {
            "Toggle"
        }
        ul {
            ForEach(reversed ? [3, 2, 1] : [1, 2, 3], id: { value in value }) { value in
                li {
                    "Item \(value)"
                }
            }
        }
    }
}

private struct RuntimeServerOnlyKey: EnvironmentKey {
    static let defaultValue = "server"
}

private extension EnvironmentValues {
    var runtimeServerOnlyValue: String {
        get { self[RuntimeServerOnlyKey.self] }
        set { self[RuntimeServerOnlyKey.self] = newValue }
    }
}

private struct RuntimeServerOnlyReader: Component {
    @Environment(\.runtimeServerOnlyValue) private var serverOnlyValue: String

    @HTMLBuilder
    var body: some HTML {
        span {
            serverOnlyValue
        }
    }
}

private struct RuntimeInvalidAfterEventComponent: ClientComponent, Sendable {
    @State private var readsServerOnlyValue = false

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            readsServerOnlyValue = true
        }) {
            "Invalidate"
        }
        if readsServerOnlyValue {
            RuntimeServerOnlyReader()
        }
    }
}

@Suite
struct SwiftHTMLHydrationRuntimeTests {
    @Test
    func eventDispatchFlushesStateIntoDOMPatches() throws {
        var session = try HydrationRuntimeSession(root: RuntimeCounterComponent())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        #expect(session.dom.html == session.artifact.html)
        #expect(session.artifact.html.contains("Count 0"))

        let update = try session.invoke(handlerID: handler.id)

        #expect(update.dirtyComponents == session.artifact.hydration.componentIDs)
        #expect(!update.patches.isEmpty)
        #expect(update.patches.contains { patch in
            if case .updateText(_, "Count 1") = patch.operation {
                return true
            }
            return false
        })
        #expect(update.commands.contains { command in
            if case .updateText(_, "Count 1") = command {
                return true
            }
            return false
        })
        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("Count 1"))
    }

    @Test
    func bidirectionalCounterUsesStateForIncrementAndDecrement() throws {
        var session = try HydrationRuntimeSession(root: RuntimeBidirectionalCounterComponent())
        let handlers = session.artifact.clientHandlers.handlers
        let decrement = try #require(handlers.first)
        let increment = try #require(handlers.dropFirst().first)

        #expect(session.artifact.html.contains("Client value 0"))

        let incrementUpdate = try session.invoke(handlerID: increment.id)

        #expect(incrementUpdate.html.contains("Client value 1"))
        #expect(incrementUpdate.commands.contains { command in
            if case .updateText(_, "Client value 1") = command {
                return true
            }
            return false
        })

        let decrementUpdate = try session.invoke(handlerID: decrement.id)

        #expect(decrementUpdate.html.contains("Client value 0"))
        #expect(decrementUpdate.commands.contains { command in
            if case .updateText(_, "Client value 0") = command {
                return true
            }
            return false
        })
    }

    @Test
    func inputEventUpdatesBoundPropertyInDOMSnapshot() throws {
        var session = try HydrationRuntimeSession(root: RuntimeTextInputComponent())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        #expect(session.artifact.html.contains("value=\"Alice\""))

        let update = try session.invoke(
            handlerID: handler.id,
            event: DOMEvent(value: "Bob")
        )

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("value=\"Bob\""))
        #expect(update.patches.contains { patch in
            if case .setProperty(_, "value", "Bob") = patch.operation {
                return true
            }
            return false
        })
        #expect(update.commands.contains { command in
            if case .setProperty(_, "value", "Bob") = command {
                return true
            }
            return false
        })
    }

    @Test
    func keyedChildrenMoveWithoutReplacingTheWholeList() throws {
        var session = try HydrationRuntimeSession(root: RuntimeReorderingComponent())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        #expect(session.artifact.html.contains("<li>Item 1</li><li>Item 2</li><li>Item 3</li>"))

        let update = try session.invoke(handlerID: handler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("<li>Item 3</li><li>Item 2</li><li>Item 1</li>"))
        #expect(update.patches.contains { patch in
            if case .moveKeyed = patch.operation {
                return true
            }
            return false
        })
        #expect(update.commands.contains { command in
            if case .moveKeyed = command {
                return true
            }
            return false
        })
        #expect(!update.patches.contains { patch in
            if case .replaceSubtree = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func browserRuntimeAppliesCommandBatchToHost() throws {
        let host = BrowserDOMCommandBuffer()
        var runtime = try BrowserHydrationRuntime(
            root: RuntimeCounterComponent(),
            host: host
        )
        let handler = try #require(runtime.session.artifact.clientHandlers.handlers.first)

        let update = try runtime.invoke(handlerID: handler.id)
        let batch = try #require(host.lastBatch())
        let index = try #require(host.lastIndex())

        #expect(batch == update.commands)
        #expect(index == update.previousHydrationIndex)
        #expect(batch.contains { command in
            if case .updateText(_, "Count 1") = command {
                return true
            }
            return false
        })
    }

    @Test
    func browserCommandBatchIsCodableForHostBoundary() throws {
        var session = try HydrationRuntimeSession(root: RuntimeTextInputComponent())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)
        let update = try session.invoke(
            handlerID: handler.id,
            event: DOMEvent(value: "Bob")
        )

        let data = try JSONEncoder().encode(update.commandBatch)
        let decoded = try JSONDecoder().decode(BrowserDOMCommandBatch.self, from: data)

        #expect(decoded == update.commandBatch)
    }

    @Test
    func failedFlushKeepsDirtyComponentsForRetry() throws {
        var session = try HydrationRuntimeSession(root: RuntimeInvalidAfterEventComponent())
        let component = try #require(session.artifact.hydration.components.first)
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        do {
            _ = try session.invoke(handlerID: handler.id)
            Issue.record("Expected hydration validation to fail")
        } catch let error as RenderDiagnosticError {
            #expect(error.diagnostics.map(\.code).contains(.serverOnlyEnvironmentInClientComponent))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        #expect(session.stateStore.dirtyComponents() == [component.id])
    }
}
