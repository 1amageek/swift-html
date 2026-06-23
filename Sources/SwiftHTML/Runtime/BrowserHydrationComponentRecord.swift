public struct BrowserHydrationComponentRecord: Sendable, Codable, Equatable {
    public let id: ComponentID
    public let typeName: String
    public let path: String
    public let nodeID: HTMLNodeID
    public let bundleID: ClientBundleID?
    public let loadPolicy: ClientLoadPolicy
    public let serverSlotIDs: [ServerSlotID]
    public let stateSlots: [StateSlotRecord]
    public let environmentSnapshot: ClientEnvironmentSnapshot

    public init(
        id: ComponentID,
        typeName: String,
        path: String,
        nodeID: HTMLNodeID,
        bundleID: ClientBundleID?,
        loadPolicy: ClientLoadPolicy,
        serverSlotIDs: [ServerSlotID],
        stateSlots: [StateSlotRecord] = [],
        environmentSnapshot: ClientEnvironmentSnapshot = ClientEnvironmentSnapshot()
    ) {
        self.id = id
        self.typeName = typeName
        self.path = path
        self.nodeID = nodeID
        self.bundleID = bundleID
        self.loadPolicy = loadPolicy
        self.serverSlotIDs = serverSlotIDs
        self.stateSlots = stateSlots.sorted { left, right in
            left.id.rawValue < right.id.rawValue
        }
        self.environmentSnapshot = environmentSnapshot
    }

    public var stateSchemaHash: String {
        StateSchema.hash(stateSlots)
    }

    #if !hasFeature(Embedded)
    private enum CodingKeys: String, CodingKey {
        case id
        case typeName
        case path
        case nodeID
        case bundleID
        case loadPolicy
        case serverSlotIDs
        case stateSlots
        case environmentSnapshot
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(ComponentID.self, forKey: .id),
            typeName: try container.decode(String.self, forKey: .typeName),
            path: try container.decode(String.self, forKey: .path),
            nodeID: try container.decode(HTMLNodeID.self, forKey: .nodeID),
            bundleID: try container.decodeIfPresent(ClientBundleID.self, forKey: .bundleID),
            loadPolicy: try container.decode(ClientLoadPolicy.self, forKey: .loadPolicy),
            serverSlotIDs: try container.decode([ServerSlotID].self, forKey: .serverSlotIDs),
            stateSlots: try container.decodeIfPresent([StateSlotRecord].self, forKey: .stateSlots) ?? [],
            environmentSnapshot: try container.decodeIfPresent(
                ClientEnvironmentSnapshot.self,
                forKey: .environmentSnapshot
            ) ?? ClientEnvironmentSnapshot()
        )
    }
    #endif
}
