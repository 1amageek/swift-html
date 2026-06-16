public struct ClientBundlePlanningOptions: Sendable, Equatable {
    public let runtimeBundleID: ClientBundleID
    public let eagerRouteBundleID: ClientBundleID
    public let sharedBundleID: ClientBundleID
    public let sharedSymbolMinimumUseCount: Int
    public let runtimeAsset: WasmAsset?

    public init(
        runtimeBundleID: ClientBundleID = ClientBundleID("runtime"),
        eagerRouteBundleID: ClientBundleID = ClientBundleID("route:initial"),
        sharedBundleID: ClientBundleID = ClientBundleID("shared"),
        sharedSymbolMinimumUseCount: Int = 2,
        runtimeAsset: WasmAsset? = nil
    ) {
        self.runtimeBundleID = runtimeBundleID
        self.eagerRouteBundleID = eagerRouteBundleID
        self.sharedBundleID = sharedBundleID
        self.sharedSymbolMinimumUseCount = max(2, sharedSymbolMinimumUseCount)
        self.runtimeAsset = runtimeAsset
    }
}
