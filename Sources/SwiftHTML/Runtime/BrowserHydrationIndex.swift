public struct BrowserHydrationIndex: Sendable, Equatable {
    private struct NodeIndexEntry: Sendable {
        let id: HTMLNodeID
        let sourceOffset: Int
        let record: BrowserHydrationNodeRecord
    }

    private struct ComponentIndexEntry: Sendable {
        let id: ComponentID
        let sourceOffset: Int
        let record: BrowserHydrationComponentRecord
    }

    public let rootID: HTMLNodeID
    public let nodes: [BrowserHydrationNodeRecord]
    public let components: [BrowserHydrationComponentRecord]
    public let serverSlots: [ServerSlotRecord]
    public let handlers: [BrowserHydrationEventBinding]
    private let nodeIndex: [NodeIndexEntry]
    private let componentIndex: [ComponentIndexEntry]

    public init(
        rootID: HTMLNodeID,
        nodes: [BrowserHydrationNodeRecord],
        components: [BrowserHydrationComponentRecord],
        serverSlots: [ServerSlotRecord],
        handlers: [BrowserHydrationEventBinding]
    ) {
        self.rootID = rootID
        self.nodes = nodes
        self.components = components
        self.serverSlots = serverSlots
        self.handlers = handlers
        self.nodeIndex = Self.makeNodeIndex(nodes)
        self.componentIndex = Self.makeComponentIndex(components)
    }

    public static let empty = BrowserHydrationIndex(
        rootID: HTMLNodeID(0),
        nodes: [],
        components: [],
        serverSlots: [],
        handlers: []
    )

    public func node(_ id: HTMLNodeID) -> BrowserHydrationNodeRecord? {
        var lowerBound = 0
        var upperBound = nodeIndex.count
        while lowerBound < upperBound {
            let midpoint = lowerBound + (upperBound - lowerBound) / 2
            if nodeIndex[midpoint].id.rawValue < id.rawValue {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        guard lowerBound < nodeIndex.count, nodeIndex[lowerBound].id == id else {
            return nil
        }
        return nodeIndex[lowerBound].record
    }

    public func component(_ id: ComponentID) -> BrowserHydrationComponentRecord? {
        var lowerBound = 0
        var upperBound = componentIndex.count
        while lowerBound < upperBound {
            let midpoint = lowerBound + (upperBound - lowerBound) / 2
            if componentIndex[midpoint].id.rawValue < id.rawValue {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        guard lowerBound < componentIndex.count, componentIndex[lowerBound].id == id else {
            return nil
        }
        return componentIndex[lowerBound].record
    }

    private static func makeNodeIndex(
        _ nodes: [BrowserHydrationNodeRecord]
    ) -> [NodeIndexEntry] {
        var result: [NodeIndexEntry] = []
        result.reserveCapacity(nodes.count)
        for (sourceOffset, node) in nodes.enumerated() {
            result.append(NodeIndexEntry(id: node.id, sourceOffset: sourceOffset, record: node))
        }
        result.sort { left, right in
            if left.id.rawValue == right.id.rawValue {
                return left.sourceOffset < right.sourceOffset
            }
            return left.id.rawValue < right.id.rawValue
        }
        return result
    }

    private static func makeComponentIndex(
        _ components: [BrowserHydrationComponentRecord]
    ) -> [ComponentIndexEntry] {
        var result: [ComponentIndexEntry] = []
        result.reserveCapacity(components.count)
        for (sourceOffset, component) in components.enumerated() {
            result.append(
                ComponentIndexEntry(
                    id: component.id,
                    sourceOffset: sourceOffset,
                    record: component
                )
            )
        }
        result.sort { left, right in
            if left.id.rawValue == right.id.rawValue {
                return left.sourceOffset < right.sourceOffset
            }
            return left.id.rawValue < right.id.rawValue
        }
        return result
    }

    #if !hasFeature(Embedded)
    private enum CodingKeys: String, CodingKey {
        case rootID
        case nodes
        case components
        case serverSlots
        case handlers
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            rootID: try container.decode(HTMLNodeID.self, forKey: .rootID),
            nodes: try container.decode([BrowserHydrationNodeRecord].self, forKey: .nodes),
            components: try container.decode([BrowserHydrationComponentRecord].self, forKey: .components),
            serverSlots: try container.decode([ServerSlotRecord].self, forKey: .serverSlots),
            handlers: try container.decode([BrowserHydrationEventBinding].self, forKey: .handlers)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rootID, forKey: .rootID)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(components, forKey: .components)
        try container.encode(serverSlots, forKey: .serverSlots)
        try container.encode(handlers, forKey: .handlers)
    }
    #endif

    public static func == (lhs: BrowserHydrationIndex, rhs: BrowserHydrationIndex) -> Bool {
        lhs.rootID == rhs.rootID
            && lhs.nodes == rhs.nodes
            && lhs.components == rhs.components
            && lhs.serverSlots == rhs.serverSlots
            && lhs.handlers == rhs.handlers
    }
}

#if !hasFeature(Embedded)
extension BrowserHydrationIndex: Codable {}
#endif
