public struct ClientComponentEntrypoint: Sendable, Equatable {
    public let componentID: ComponentID
    public let typeName: String
    public let entrySymbols: [ClientSymbolID]
    public let loadPolicy: ClientLoadPolicy
    public let serverSlots: [ServerSlotID]

    public init(
        componentID: ComponentID,
        typeName: String,
        entrySymbols: [ClientSymbolID],
        loadPolicy: ClientLoadPolicy = .eager,
        serverSlots: [ServerSlotID] = []
    ) {
        self.componentID = componentID
        self.typeName = typeName
        self.entrySymbols = entrySymbols.sorted()
        self.loadPolicy = loadPolicy
        self.serverSlots = serverSlots.sorted()
    }
}

#if !hasFeature(Embedded)
extension ClientComponentEntrypoint: Codable {}
#endif
