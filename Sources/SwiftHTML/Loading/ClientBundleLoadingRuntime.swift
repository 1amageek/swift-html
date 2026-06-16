public struct ClientBundleLoadingRuntime: Sendable {
    public let manifest: ClientBundleManifest

    private let resolver: ClientBundleLoadResolver
    private var statuses: [ClientBundleID: ClientBundleRuntimeStatus]

    public init(manifest: ClientBundleManifest) {
        self.manifest = manifest
        self.resolver = ClientBundleLoadResolver(manifest: manifest)
        var statuses: [ClientBundleID: ClientBundleRuntimeStatus] = [:]
        statuses.reserveCapacity(manifest.bundles.count)
        for bundle in manifest.bundles {
            statuses[bundle.id] = .pending
        }
        self.statuses = statuses
    }

    public func status(for bundleID: ClientBundleID) -> ClientBundleRuntimeStatus {
        statuses[bundleID] ?? .pending
    }

    public var loadedBundleIDs: [ClientBundleID] {
        statuses.compactMap { bundleID, status in
            status == .loaded ? bundleID : nil
        }
        .sorted()
    }

    public var loadingBundleIDs: [ClientBundleID] {
        statuses.compactMap { bundleID, status in
            status == .loading ? bundleID : nil
        }
        .sorted()
    }

    public mutating func scheduleInitial() throws -> ClientBundleRuntimeBatch {
        try schedule(resolver.initialPlan())
    }

    public mutating func schedule(loadPolicy: ClientLoadPolicy) throws -> ClientBundleRuntimeBatch {
        try schedule(resolver.plan(for: loadPolicy))
    }

    public mutating func schedule(componentID: ComponentID) throws -> ClientBundleRuntimeBatch {
        try schedule(resolver.plan(for: componentID))
    }

    public mutating func scheduleAutomaticStages() throws -> [ClientBundleRuntimeBatch] {
        try resolver.incrementalStagedPlans().map { plan in
            schedule(plan)
        }
    }

    public mutating func scheduleAllStagesIncludingManual() throws -> [ClientBundleRuntimeBatch] {
        try resolver.incrementalStagedPlans(includeManual: true).map { plan in
            schedule(plan)
        }
    }

    public mutating func complete(_ batch: ClientBundleRuntimeBatch) {
        complete(batch.bundleIDs)
    }

    public mutating func complete(_ bundleIDs: [ClientBundleID]) {
        for bundleID in bundleIDs {
            statuses[bundleID] = .loaded
        }
    }

    public mutating func fail(_ bundleID: ClientBundleID) {
        statuses[bundleID] = .failed
    }

    private mutating func schedule(_ plan: ClientBundleLoadPlan) -> ClientBundleRuntimeBatch {
        var scheduled: [ClientBundleRecord] = []
        var skipped: [ClientBundleID] = []

        for bundle in plan.bundles {
            switch statuses[bundle.id, default: .pending] {
            case .pending, .failed:
                statuses[bundle.id] = .loading
                scheduled.append(bundle)
            case .loading, .loaded:
                skipped.append(bundle.id)
            }
        }

        return ClientBundleRuntimeBatch(
            loadPolicy: plan.loadPolicy,
            bundles: scheduled,
            skippedBundleIDs: skipped
        )
    }
}
