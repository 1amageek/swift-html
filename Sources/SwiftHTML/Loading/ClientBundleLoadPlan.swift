public struct ClientBundleLoadPlan: Sendable, Codable, Equatable {
    public let loadPolicy: ClientLoadPolicy
    public let bundles: [ClientBundleRecord]
    public let components: [ClientComponentAsset]

    public init(
        loadPolicy: ClientLoadPolicy,
        bundles: [ClientBundleRecord],
        components: [ClientComponentAsset]
    ) {
        self.loadPolicy = loadPolicy
        self.bundles = bundles
        self.components = components.sorted { left, right in
            left.componentID.rawValue < right.componentID.rawValue
        }
    }

    public var bundleIDs: [ClientBundleID] {
        bundles.map(\.id)
    }

    public var estimatedByteSize: Int {
        bundles.reduce(0) { total, bundle in
            total + bundle.estimatedByteSize
        }
    }
}
