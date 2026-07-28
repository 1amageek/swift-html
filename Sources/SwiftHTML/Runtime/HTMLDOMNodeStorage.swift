public struct HTMLDOMNodeStorage: Sendable, Equatable {
    private struct Entry: Sendable, Equatable {
        let id: HTMLNodeID
        var node: HTMLDOMNode
    }

    private var storage: [Entry]

    public init(_ nodes: [HTMLNodeID: HTMLDOMNode]) {
        var storage: [Entry] = []
        storage.reserveCapacity(nodes.count)
        for (id, node) in nodes {
            storage.append(Entry(id: id, node: node))
        }
        storage.sort { $0.id.rawValue < $1.id.rawValue }
        self.storage = storage
    }

    init(_ nodes: [HTMLDOMNode]) {
        var storage: [Entry] = []
        storage.reserveCapacity(nodes.count)
        for node in nodes {
            storage.append(Entry(id: node.id, node: node))
        }
        storage.sort { $0.id.rawValue < $1.id.rawValue }
        self.storage = storage
    }

    public var count: Int {
        storage.count
    }

    public subscript(_ id: HTMLNodeID) -> HTMLDOMNode? {
        get {
            let index = lowerBound(for: id)
            guard index < storage.count, storage[index].id == id else {
                return nil
            }
            return storage[index].node
        }
        set {
            let index = lowerBound(for: id)
            if index < storage.count, storage[index].id == id {
                if let newValue {
                    storage[index].node = newValue
                } else {
                    storage.remove(at: index)
                }
            } else if let newValue {
                storage.insert(Entry(id: id, node: newValue), at: index)
            }
        }
    }

    private func lowerBound(for id: HTMLNodeID) -> Int {
        var lowerBound = 0
        var upperBound = storage.count
        while lowerBound < upperBound {
            let midpoint = lowerBound + (upperBound - lowerBound) / 2
            if storage[midpoint].id.rawValue < id.rawValue {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        return lowerBound
    }
}
