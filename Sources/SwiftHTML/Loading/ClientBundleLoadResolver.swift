public struct ClientBundleLoadResolver: Sendable {
    public let manifest: ClientBundleManifest

    private let bundlesByID: [ClientBundleID: ClientBundleRecord]
    private let componentsByID: [ComponentID: ClientComponentAsset]
    private let componentsByLoadPolicy: [ClientLoadPolicy: [ClientComponentAsset]]

    public init(manifest: ClientBundleManifest) {
        self.manifest = manifest
        self.bundlesByID = Self.indexBundles(manifest.bundles)
        self.componentsByID = Self.indexComponents(manifest.components)
        self.componentsByLoadPolicy = Self.indexComponentsByLoadPolicy(manifest.components)
    }

    public func initialPlan() throws -> ClientBundleLoadPlan {
        let eagerPlan = try plan(for: .eager)
        guard
            !manifest.components.isEmpty,
            let runtimeBundleID = manifest.runtimeBundleID,
            !eagerPlan.bundleIDs.contains(runtimeBundleID)
        else {
            return eagerPlan
        }

        let runtimeBundles = try resolveBundles(startingAt: [runtimeBundleID])
        return ClientBundleLoadPlan(
            loadPolicy: .eager,
            bundles: uniqueBundles(runtimeBundles + eagerPlan.bundles),
            components: eagerPlan.components
        )
    }

    public func stagedPlans() throws -> [ClientBundleLoadPlan] {
        try ClientLoadPolicy.allCases.map { policy in
            if policy == .eager {
                return try initialPlan()
            }
            return try plan(for: policy)
        }
    }

    public func incrementalStagedPlans(includeManual: Bool = false) throws -> [ClientBundleLoadPlan] {
        var loadedBundleIDs = Set<ClientBundleID>()
        return try stagedPlans().filter { plan in
            includeManual || plan.loadPolicy != .manual
        }.map { plan in
            let bundles = plan.bundles.filter { bundle in
                loadedBundleIDs.insert(bundle.id).inserted
            }
            return ClientBundleLoadPlan(
                loadPolicy: plan.loadPolicy,
                bundles: bundles,
                components: plan.components
            )
        }
    }

    public func plan(for loadPolicy: ClientLoadPolicy) throws -> ClientBundleLoadPlan {
        let components = componentsByLoadPolicy[loadPolicy, default: []]
        let bundleIDs = Set(components.map { $0.bundleID })
        return ClientBundleLoadPlan(
            loadPolicy: loadPolicy,
            bundles: try resolveBundles(startingAt: bundleIDs),
            components: components
        )
    }

    public func plan(for componentID: ComponentID) throws -> ClientBundleLoadPlan {
        guard let component = componentsByID[componentID] else {
            throw ClientBundleLoadResolutionError.missingComponent(componentID)
        }

        return ClientBundleLoadPlan(
            loadPolicy: component.loadPolicy,
            bundles: try resolveBundles(startingAt: [component.bundleID]),
            components: [component]
        )
    }

    private func resolveBundles(startingAt bundleIDs: Set<ClientBundleID>) throws -> [ClientBundleRecord] {
        var result: [ClientBundleRecord] = []
        var visited = Set<ClientBundleID>()
        var active = Set<ClientBundleID>()
        var activeStack: [ClientBundleID] = []

        for bundleID in bundleIDs.sorted() {
            try visit(
                bundleID,
                result: &result,
                visited: &visited,
                active: &active,
                activeStack: &activeStack
            )
        }

        return result
    }

    private func visit(
        _ bundleID: ClientBundleID,
        result: inout [ClientBundleRecord],
        visited: inout Set<ClientBundleID>,
        active: inout Set<ClientBundleID>,
        activeStack: inout [ClientBundleID]
    ) throws {
        if visited.contains(bundleID) {
            return
        }

        if active.contains(bundleID) {
            let cycleStart = activeStack.firstIndex(of: bundleID) ?? activeStack.startIndex
            throw ClientBundleLoadResolutionError.cyclicBundleDependency(
                Array(activeStack[cycleStart...]) + [bundleID]
            )
        }

        guard let bundle = bundlesByID[bundleID] else {
            throw ClientBundleLoadResolutionError.missingBundle(bundleID)
        }

        active.insert(bundleID)
        activeStack.append(bundleID)
        defer {
            active.remove(bundleID)
            activeStack.removeLast()
        }

        for dependency in bundle.dependencies.sorted() {
            try visit(
                dependency,
                result: &result,
                visited: &visited,
                active: &active,
                activeStack: &activeStack
            )
        }

        visited.insert(bundleID)
        result.append(bundle)
    }

    private func uniqueBundles(_ bundles: [ClientBundleRecord]) -> [ClientBundleRecord] {
        var seen = Set<ClientBundleID>()
        return bundles.filter { bundle in
            seen.insert(bundle.id).inserted
        }
    }

    private static func indexBundles(_ bundles: [ClientBundleRecord]) -> [ClientBundleID: ClientBundleRecord] {
        var result: [ClientBundleID: ClientBundleRecord] = [:]
        result.reserveCapacity(bundles.count)
        for bundle in bundles {
            result[bundle.id] = bundle
        }
        return result
    }

    private static func indexComponents(_ components: [ClientComponentAsset]) -> [ComponentID: ClientComponentAsset] {
        var result: [ComponentID: ClientComponentAsset] = [:]
        result.reserveCapacity(components.count)
        for component in components {
            result[component.componentID] = component
        }
        return result
    }

    private static func indexComponentsByLoadPolicy(
        _ components: [ClientComponentAsset]
    ) -> [ClientLoadPolicy: [ClientComponentAsset]] {
        var result: [ClientLoadPolicy: [ClientComponentAsset]] = [:]
        for component in components {
            result[component.loadPolicy, default: []].append(component)
        }
        return result
    }
}
