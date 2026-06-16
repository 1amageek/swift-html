public struct BrowserHydrationComponentRecord: Sendable, Codable, Equatable {
    public let id: ComponentID
    public let typeName: String
    public let path: String
    public let nodeID: HTMLNodeID
    public let bundleID: ClientBundleID?
    public let loadPolicy: ClientLoadPolicy
    public let serverSlotIDs: [ServerSlotID]
    public let environmentSnapshot: ClientEnvironmentSnapshot

    public init(
        id: ComponentID,
        typeName: String,
        path: String,
        nodeID: HTMLNodeID,
        bundleID: ClientBundleID?,
        loadPolicy: ClientLoadPolicy,
        serverSlotIDs: [ServerSlotID],
        environmentSnapshot: ClientEnvironmentSnapshot = ClientEnvironmentSnapshot()
    ) {
        self.id = id
        self.typeName = typeName
        self.path = path
        self.nodeID = nodeID
        self.bundleID = bundleID
        self.loadPolicy = loadPolicy
        self.serverSlotIDs = serverSlotIDs
        self.environmentSnapshot = environmentSnapshot
    }
}
