public struct ClientBundleManifest: Sendable, Equatable {
    public let runtimeBundleID: ClientBundleID?
    public let bundles: [ClientBundleRecord]
    public let components: [ClientComponentAsset]
    public let serverSlots: [ServerSlotRecord]

    public init(
        runtimeBundleID: ClientBundleID? = nil,
        bundles: [ClientBundleRecord] = [],
        components: [ClientComponentAsset] = [],
        serverSlots: [ServerSlotRecord] = []
    ) {
        self.runtimeBundleID = runtimeBundleID
        self.bundles = bundles.sorted { left, right in
            left.id < right.id
        }
        self.components = components.sorted { left, right in
            left.componentID.rawValue < right.componentID.rawValue
        }
        self.serverSlots = serverSlots.sorted { left, right in
            left.id < right.id
        }
    }

    public func bundle(_ id: ClientBundleID) -> ClientBundleRecord? {
        bundles.first { bundle in
            bundle.id == id
        }
    }

    public func component(_ id: ComponentID) -> ClientComponentAsset? {
        components.first { component in
            component.componentID == id
        }
    }
}

#if !hasFeature(Embedded)
extension ClientBundleManifest: Codable {}
#endif
