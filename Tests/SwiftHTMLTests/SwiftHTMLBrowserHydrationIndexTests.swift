import Foundation
import SwiftHTML
import Testing

private struct IndexCounterComponent: ClientComponent, Sendable {
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

private struct IndexOuterClient: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        div(.class("outer")) {
            IndexServerSlot()
        }
    }
}

private struct IndexServerSlot: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        section(.class("server-slot")) {
            span {
                "Server"
            }
            IndexInnerClient()
        }
    }
}

private struct IndexInnerClient: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {}) {
            "Inner"
        }
    }
}

@Suite
struct SwiftHTMLBrowserHydrationIndexTests {
    @Test
    func indexRecordsNodesHandlersAndComponents() throws {
        let artifact = IndexCounterComponent().renderArtifact()
        let index = artifact.browserHydrationIndex()
        let component = try #require(artifact.hydration.components.first)
        let binding = try #require(index.handlers.first)
        let node = try #require(index.node(binding.nodeID))

        #expect(index.rootID == artifact.rootID)
        #expect(index.nodes.count == artifact.nodeCount)
        #expect(index.components.count == 1)
        #expect(index.component(component.id)?.nodeID == component.nodeID)
        #expect(binding.eventName == "click")
        #expect(binding.componentID == component.id)
        #expect(node.role == .element)
        #expect(node.name == "button")
        #expect(node.eventBindings == [binding])
    }

    @Test
    func indexRecordsLayeredClientServerBoundaries() throws {
        let artifact = IndexOuterClient().renderArtifact()
        let index = artifact.browserHydrationIndex()
        let serverSlot = try #require(index.serverSlots.first)
        let serverSlotNode = try #require(index.node(serverSlot.nodeID))

        #expect(index.components.count == 2)
        #expect(index.serverSlots.count == 1)
        #expect(serverSlotNode.role == .serverSlot)
        #expect(serverSlotNode.serverSlotID == serverSlot.id)
        #expect(index.components.contains { component in
            component.id == serverSlot.ownerComponentID
                && component.serverSlotIDs == [serverSlot.id]
        })
        #expect(index.handlers.count == 1)
        #expect(index.handlers.first?.eventName == "click")
    }

    @Test
    func commandTargetsAreResolvableThroughHydrationIndex() throws {
        var session = try HydrationRuntimeSession(root: IndexCounterComponent())
        let index = session.artifact.browserHydrationIndex()
        let handler = try #require(session.artifact.clientHandlers.handlers.first)

        let update = try session.invoke(handlerID: handler.id)
        let targetIDs = update.commands.flatMap(targetNodeIDs)

        #expect(!targetIDs.isEmpty)
        #expect(update.hydrationIndex.nodes.count == session.artifact.nodeCount)
        #expect(targetIDs.allSatisfy { id in
            index.node(id) != nil
        })
    }

    @Test
    func indexIsCodableForClientRuntimeBoundary() throws {
        let artifact = IndexOuterClient().renderArtifact()
        let index = artifact.browserHydrationIndex()

        let data = try JSONEncoder().encode(index)
        let decoded = try JSONDecoder().decode(BrowserHydrationIndex.self, from: data)

        #expect(decoded == index)
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
