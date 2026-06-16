public struct ClientBundleRuntimeBatch: Sendable, Equatable {
    public let loadPolicy: ClientLoadPolicy
    public let bundles: [ClientBundleRecord]
    public let skippedBundleIDs: [ClientBundleID]

    public init(
        loadPolicy: ClientLoadPolicy,
        bundles: [ClientBundleRecord],
        skippedBundleIDs: [ClientBundleID] = []
    ) {
        self.loadPolicy = loadPolicy
        self.bundles = bundles
        self.skippedBundleIDs = skippedBundleIDs
    }

    public var bundleIDs: [ClientBundleID] {
        bundles.map(\.id)
    }

    public var missingAssetBundleIDs: [ClientBundleID] {
        bundles.compactMap { bundle in
            bundle.asset == nil ? bundle.id : nil
        }
    }

    public var estimatedByteSize: Int {
        bundles.reduce(0) { total, bundle in
            total + bundle.estimatedByteSize
        }
    }

    public var isEmpty: Bool {
        bundles.isEmpty
    }
}
