public struct BrowserHydrationIndex: Sendable, Equatable {
    public let rootID: HTMLNodeID
    public let nodes: [BrowserHydrationNodeRecord]
    public let components: [BrowserHydrationComponentRecord]
    public let serverSlots: [ServerSlotRecord]
    public let handlers: [BrowserHydrationEventBinding]
    private let nodesByID: [HTMLNodeID: BrowserHydrationNodeRecord]
    private let componentsByID: [ComponentID: BrowserHydrationComponentRecord]

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
        self.nodesByID = Self.index(nodes) { node in
            node.id
        }
        self.componentsByID = Self.index(components) { component in
            component.id
        }
    }

    public static let empty = BrowserHydrationIndex(
        rootID: HTMLNodeID(0),
        nodes: [],
        components: [],
        serverSlots: [],
        handlers: []
    )

    public func node(_ id: HTMLNodeID) -> BrowserHydrationNodeRecord? {
        nodesByID[id]
    }

    public func component(_ id: ComponentID) -> BrowserHydrationComponentRecord? {
        componentsByID[id]
    }

    private static func index<Key: Hashable, Value>(
        _ values: [Value],
        by key: (Value) -> Key
    ) -> [Key: Value] {
        var result: [Key: Value] = [:]
        result.reserveCapacity(values.count)
        for value in values {
            let valueKey = key(value)
            if result[valueKey] == nil {
                result[valueKey] = value
            }
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
