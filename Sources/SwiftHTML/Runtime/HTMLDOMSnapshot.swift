public struct HTMLDOMSnapshot: Sendable, Equatable {
    public var rootID: HTMLNodeID
    public var nodes: HTMLDOMNodeStorage

    public init(rootID: HTMLNodeID, nodes: [HTMLNodeID: HTMLDOMNode]) {
        self.rootID = rootID
        self.nodes = HTMLDOMNodeStorage(nodes)
    }

    init(graph: HTMLGraph, rootID: HTMLNodeID) {
        var nodes: [HTMLDOMNode] = []
        nodes.reserveCapacity(graph.nodes.count)

        for index in graph.nodes.indices {
            let id = HTMLNodeID(index)
            let record = graph.nodes[index]
            nodes.append(HTMLDOMNode(
                id: id,
                kind: Self.kind(record.kind, graph: graph),
                attributes: graph.attributes(of: id),
                children: graph.children(of: id).map(HTMLDOMChild.node),
                flags: record.flags,
                key: record.key
            ))
        }

        self.rootID = rootID
        self.nodes = HTMLDOMNodeStorage(nodes)
    }

    public var html: String {
        HTMLDOMSerializer().render(self)
    }

    private static func kind(_ kind: HTMLNodeKind, graph: HTMLGraph) -> HTMLDOMNodeKind {
        switch kind {
        case .document:
            .document
        case .doctype:
            .doctype
        case .element(let id):
            .element(graph.string(id))
        case .text(let id):
            .text(graph.string(id))
        case .rawHTML(let id):
            .rawHTML(graph.string(id))
        case .fragment:
            .fragment
        case .component(let id):
            .component(id)
        case .serverSlot(let id):
            .serverSlot(id)
        case .placeholder(let id):
            .placeholder(graph.string(id))
        case .comment(let id):
            .comment(graph.string(id))
        }
    }
}
