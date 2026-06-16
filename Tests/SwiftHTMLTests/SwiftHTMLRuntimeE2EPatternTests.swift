import SwiftHTML
import Testing

private struct E2ECounter: ClientComponent, Sendable {
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

private struct E2ETextInput: ClientComponent, Sendable {
    @State private var value = "Alice"

    @HTMLBuilder
    var body: some HTML {
        input(
            .type(InputType.text),
            .value($value),
            .onInput { event in
                value = event.value ?? ""
            }
        )
    }
}

private struct E2ECheckbox: ClientComponent, Sendable {
    @State private var checked = false

    @HTMLBuilder
    var body: some HTML {
        input(
            .type(InputType.checkbox),
            .checked($checked),
            .onChange { event in
                checked = event.checked ?? false
            }
        )
    }
}

private struct E2EKeyedReorder: ClientComponent, Sendable {
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

private struct E2EAppendList: ClientComponent, Sendable {
    @State private var values = [1, 2]

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            values.append((values.last ?? 0) + 1)
        }) {
            "Append"
        }
        ul {
            ForEach(values, id: { value in value }) { value in
                li {
                    "Item \(value)"
                }
            }
        }
    }
}

private struct E2EOuterClient: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        div(.class("outer")) {
            E2EServerSlot()
        }
    }
}

private struct E2EServerSlot: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        section(.class("server-slot")) {
            span {
                "Server value"
            }
            E2EInnerClient()
        }
    }
}

private struct E2EInnerClient: ClientComponent, Sendable {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Inner \(count)"
        }
    }
}

@Suite
struct SwiftHTMLRuntimeE2EPatternTests {
    @Test
    func counterPatternHydratesAndPatchesText() throws {
        var session = try HydrationRuntimeSession(root: E2ECounter())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(handlerID: handler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("Count 1"))
        #expect(update.commands.contains { command in
            if case .updateText(_, "Count 1") = command {
                return true
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func textInputPatternHydratesAndPatchesProperty() throws {
        var session = try HydrationRuntimeSession(root: E2ETextInput())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(
            handlerID: handler.id,
            event: DOMEvent(value: "Bob")
        )

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("value=\"Bob\""))
        #expect(update.commands.contains { command in
            if case .setProperty(_, "value", "Bob") = command {
                return true
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func checkboxPatternHydratesAndPatchesBooleanProperty() throws {
        var session = try HydrationRuntimeSession(root: E2ECheckbox())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(
            handlerID: handler.id,
            event: DOMEvent(checked: true)
        )

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains(" checked"))
        #expect(update.commands.contains { command in
            if case .setProperty(_, "checked", "true") = command {
                return true
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func keyedReorderPatternMovesNodesWithoutSubtreeReplacement() throws {
        var session = try HydrationRuntimeSession(root: E2EKeyedReorder())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(handlerID: handler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("<li>Item 3</li><li>Item 2</li><li>Item 1</li>"))
        #expect(update.commands.contains { command in
            if case .moveKeyed = command {
                return true
            }
            return false
        })
        #expect(!update.commands.contains { command in
            if case .replaceSubtree = command {
                return true
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func keyedInsertionPatternEmitsInsertHTMLCommand() throws {
        var session = try HydrationRuntimeSession(root: E2EAppendList())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(handlerID: handler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("<li>Item 1</li><li>Item 2</li><li>Item 3</li>"))
        #expect(update.commands.contains { command in
            if case .insertHTML(_, _, let html) = command {
                return html.contains("Item 3")
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func repeatedKeyedInsertionKeepsDOMSnapshotAlignedWithHydrationIndex() throws {
        var session = try HydrationRuntimeSession(root: E2EAppendList())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        _ = try session.invoke(handlerID: handler.id)
        let update = try session.invoke(handlerID: handler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("<li>Item 4</li>"))
        #expect(update.commands.contains { command in
            if case .insertHTML(_, 3, let html) = command {
                return html.contains("Item 4")
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    @Test
    func layeredServerClientPatternKeepsServerSlotStable() throws {
        var session = try HydrationRuntimeSession(root: E2EOuterClient())
        let innerHandler = try #require(session.artifact.clientHandlers.handlers.first)
        let initialIndex = session.artifact.browserHydrationIndex()
        let serverSlot = try #require(initialIndex.serverSlots.first)

        let update = try session.invoke(handlerID: innerHandler.id)

        #expect(update.html == session.artifact.html)
        #expect(update.html.contains("Server value"))
        #expect(update.html.contains("Inner 1"))
        #expect(update.hydrationIndex.serverSlots.map(\.id) == [serverSlot.id])
        #expect(update.commands.contains { command in
            if case .updateText(_, "Inner 1") = command {
                return true
            }
            return false
        })
        try assertCommandTargetsResolve(update)
    }

    private func assertCommandTargetsResolve(_ update: HydrationRuntimeUpdate) throws {
        let targetIDs = update.commands.flatMap(targetNodeIDs)
        #expect(!targetIDs.isEmpty)
        for id in targetIDs {
            _ = try #require(update.hydrationIndex.node(id))
        }
    }

    private func targetNodeIDs(for command: BrowserDOMCommand) -> [HTMLNodeID] {
        switch command {
        case .replaceNode(let node, let replacement):
            [node, replacement]
        case .replaceSubtree(let node, _):
            [node]
        case .updateText(let node, _):
            [node]
        case .updateComment(let node, _):
            [node]
        case .updateAttributes(let node, _):
            [node]
        case .setProperty(let node, _, _):
            [node]
        case .insertNode(let parent, _, let node):
            [parent, node]
        case .insertHTML(let parent, _, _):
            [parent]
        case .remove(let parent, _, let node):
            [parent, node]
        case .move(let parent, _, _, _):
            [parent]
        case .moveKeyed(let parent, _, _):
            [parent]
        }
    }
}
