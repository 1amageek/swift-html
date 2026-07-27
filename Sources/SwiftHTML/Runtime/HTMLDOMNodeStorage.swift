public struct HTMLDOMNodeStorage: Sendable, Equatable {
    private var storage: [HTMLNodeID: HTMLDOMNode]

    public init(_ nodes: [HTMLNodeID: HTMLDOMNode]) {
        self.storage = nodes
    }

    init(_ nodes: [HTMLDOMNode]) {
        self.storage = Dictionary(
            uniqueKeysWithValues: nodes.map { node in
                (node.id, node)
            }
        )
    }

    public var count: Int {
        storage.count
    }

    public subscript(_ id: HTMLNodeID) -> HTMLDOMNode? {
        get {
            storage[id]
        }
        set {
            storage[id] = newValue
        }
    }
}
