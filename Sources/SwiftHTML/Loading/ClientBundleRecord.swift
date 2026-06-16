public struct ClientBundleRecord: Sendable, Codable, Equatable {
    public let id: ClientBundleID
    public let kind: ClientBundleKind
    public let asset: WasmAsset?
    public let symbols: [ClientSymbolID]
    public let dependencies: [ClientBundleID]
    public let components: [ComponentID]
    public let loadPolicy: ClientLoadPolicy
    public let estimatedByteSize: Int

    public init(
        id: ClientBundleID,
        kind: ClientBundleKind,
        asset: WasmAsset? = nil,
        symbols: [ClientSymbolID],
        dependencies: [ClientBundleID] = [],
        components: [ComponentID] = [],
        loadPolicy: ClientLoadPolicy = .eager,
        estimatedByteSize: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.asset = asset
        self.symbols = symbols.sorted()
        self.dependencies = dependencies.sorted()
        self.components = components.sorted { left, right in
            left.rawValue < right.rawValue
        }
        self.loadPolicy = loadPolicy
        self.estimatedByteSize = estimatedByteSize
    }
}
