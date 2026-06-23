import SwiftHTMLEmbedded
import Testing

@Suite
struct SwiftHTMLEmbeddedTests {
    @Test
    func documentMountsElementsAndTextIntoHost() {
        let host = RecordingDOMHost()
        let root = host.root()
        let document = EmbeddedHTMLDocument {
            main(.id("app")) {
                h1 {
                    "Embedded SwiftHTML"
                }
                p(.class("lead")) {
                    "Small static runtime"
                }
                button(.id("increment"), .type("button")) {
                    "Increment"
                }
            }
        }

        document.mount(into: host, parent: root)

        #expect(host.operations == [
            "createElement:main",
            "setAttribute:1:id=app",
            "createElement:h1",
            "createText:Embedded SwiftHTML",
            "append:3->2",
            "append:2->1",
            "createElement:p",
            "setAttribute:4:class=lead",
            "createText:Small static runtime",
            "append:5->4",
            "append:4->1",
            "createElement:button",
            "setAttribute:6:id=increment",
            "setAttribute:6:type=button",
            "createText:Increment",
            "append:7->6",
            "append:6->1",
            "append:1->0",
        ])
    }
}

private final class RecordingDOMHost: EmbeddedDOMHost {
    struct Node: Equatable {
        let id: Int
    }

    private var nextID = 0
    private(set) var operations: [String] = []

    func root() -> Node {
        Node(id: allocateID())
    }

    func createElement(_ tagName: String) -> Node {
        let node = Node(id: allocateID())
        operations.append("createElement:\(tagName)")
        return node
    }

    func createText(_ text: String) -> Node {
        let node = Node(id: allocateID())
        operations.append("createText:\(text)")
        return node
    }

    func setAttribute(_ attribute: EmbeddedHTMLAttribute, on node: Node) {
        operations.append("setAttribute:\(node.id):\(attribute.name)=\(attribute.value)")
    }

    func appendChild(_ child: Node, to parent: Node) {
        operations.append("append:\(child.id)->\(parent.id)")
    }

    private func allocateID() -> Int {
        let id = nextID
        nextID += 1
        return id
    }
}
