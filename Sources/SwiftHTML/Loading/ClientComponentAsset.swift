public struct ClientComponentAsset: Sendable, Codable, Equatable {
    public let componentID: ComponentID
    public let typeName: String
    public let bundleID: ClientBundleID
    public let loadPolicy: ClientLoadPolicy
    public let entrySymbols: [ClientSymbolID]
    public let serverSlots: [ServerSlotID]

    public init(
        componentID: ComponentID,
        typeName: String,
        bundleID: ClientBundleID,
        loadPolicy: ClientLoadPolicy,
        entrySymbols: [ClientSymbolID],
        serverSlots: [ServerSlotID] = []
    ) {
        self.componentID = componentID
        self.typeName = typeName
        self.bundleID = bundleID
        self.loadPolicy = loadPolicy
        self.entrySymbols = entrySymbols.sorted()
        self.serverSlots = serverSlots.sorted()
    }
}
