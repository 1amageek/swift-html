public struct ClientBundlePlanner: Sendable {
    public let options: ClientBundlePlanningOptions

    public init(options: ClientBundlePlanningOptions = ClientBundlePlanningOptions()) {
        self.options = options
    }

    public func plan(_ graph: ClientSymbolGraph) -> ClientBundleManifest {
        let symbolSizes = Dictionary(uniqueKeysWithValues: graph.symbols.map { symbol in
            (symbol.id, symbol.estimatedByteSize)
        })
        let dependencyMap = makeDependencyMap(graph)
        let groups = stronglyConnectedSymbolGroups(
            symbols: allSymbols(in: graph, dependencyMap: dependencyMap),
            dependencyMap: dependencyMap
        )
        let symbolToGroup = makeSymbolToGroup(groups)
        let groupDependencies = makeGroupDependencies(
            groups: groups,
            symbolToGroup: symbolToGroup,
            dependencyMap: dependencyMap
        )
        let runtimeGroups = reachableGroups(
            from: graph.runtimeSymbols,
            symbolToGroup: symbolToGroup,
            groupDependencies: groupDependencies
        )
        let componentGroups = makeComponentGroups(
            graph.components,
            symbolToGroup: symbolToGroup,
            groupDependencies: groupDependencies
        )
        let sharedGroups = sharedGroups(
            componentGroups: componentGroups,
            excluding: runtimeGroups
        )
        let eagerGroups = eagerRouteGroups(
            components: graph.components,
            componentGroups: componentGroups,
            runtimeGroups: runtimeGroups,
            sharedGroups: sharedGroups
        )

        var draftBundles: [BundleDraft] = []
        if !runtimeGroups.isEmpty {
            draftBundles.append(BundleDraft(
                id: options.runtimeBundleID,
                kind: .runtime,
                groups: runtimeGroups,
                components: [],
                loadPolicy: .eager,
                asset: options.runtimeAsset
            ))
        }
        if !sharedGroups.isEmpty {
            draftBundles.append(BundleDraft(
                id: options.sharedBundleID,
                kind: .shared,
                groups: sharedGroups,
                components: [],
                loadPolicy: .eager
            ))
        }
        let eagerComponents = graph.components.filter { component in
            component.loadPolicy == .eager
        }
        if !eagerGroups.isEmpty {
            draftBundles.append(BundleDraft(
                id: options.eagerRouteBundleID,
                kind: .route,
                groups: eagerGroups,
                components: eagerComponents.map { $0.componentID },
                loadPolicy: .eager
            ))
        }

        for component in graph.components where component.loadPolicy != .eager {
            let groups = componentGroups[component.componentID, default: []]
                .subtracting(runtimeGroups)
                .subtracting(sharedGroups)
            guard !groups.isEmpty else {
                continue
            }
            draftBundles.append(BundleDraft(
                id: componentBundleID(for: component),
                kind: .component,
                groups: groups,
                components: [component.componentID],
                loadPolicy: component.loadPolicy
            ))
        }

        let symbolToBundle = makeSymbolToBundle(
            bundles: draftBundles,
            groups: groups
        )
        let bundleRecords = draftBundles.map { bundle in
            makeBundleRecord(
                bundle,
                groups: groups,
                symbolSizes: symbolSizes,
                symbolToBundle: symbolToBundle,
                dependencyMap: dependencyMap
            )
        }
        let componentAssets = makeComponentAssets(
            graph.components,
            componentGroups: componentGroups,
            symbolToBundle: symbolToBundle,
            runtimeGroups: runtimeGroups,
            sharedGroups: sharedGroups,
            eagerGroups: eagerGroups
        )

        return ClientBundleManifest(
            runtimeBundleID: runtimeGroups.isEmpty ? nil : options.runtimeBundleID,
            bundles: bundleRecords,
            components: componentAssets
        )
    }

    public func plan(
        hydration: HydrationManifest,
        symbolGraph graph: ClientSymbolGraph
    ) -> ClientBundleManifest {
        let slotRecords = hydration.components.flatMap { $0.serverSlots }
        let slotsByComponent = Dictionary(grouping: slotRecords) { slot in
            slot.ownerComponentID
        }
        let components = graph.components.map { component in
            let slotIDs = Set(component.serverSlots).union(
                Set(slotsByComponent[component.componentID, default: []].map { $0.id })
            )
            return ClientComponentEntrypoint(
                componentID: component.componentID,
                typeName: component.typeName,
                entrySymbols: component.entrySymbols,
                loadPolicy: component.loadPolicy,
                serverSlots: Array(slotIDs)
            )
        }
        let manifest = plan(ClientSymbolGraph(
            symbols: graph.symbols,
            dependencies: graph.dependencies,
            components: components,
            runtimeSymbols: graph.runtimeSymbols
        ))
        let hydrationComponents = Dictionary(
            uniqueKeysWithValues: hydration.components.map { component in
                (component.id, component)
            }
        )
        let hydratedComponents = manifest.components.map { component in
            guard let hydrationComponent = hydrationComponents[component.componentID] else {
                return component
            }
            return ClientComponentAsset(
                componentID: component.componentID,
                typeName: component.typeName,
                bundleID: component.bundleID,
                loadPolicy: component.loadPolicy,
                entrySymbols: component.entrySymbols,
                serverSlots: component.serverSlots,
                stateSchemaHash: hydrationComponent.stateSchemaHash,
                environmentSchemaHash: hydrationComponent.environmentSnapshot.schemaHash
            )
        }
        return ClientBundleManifest(
            runtimeBundleID: manifest.runtimeBundleID,
            bundles: manifest.bundles,
            components: hydratedComponents,
            serverSlots: slotRecords
        )
    }

    private func makeDependencyMap(_ graph: ClientSymbolGraph) -> [ClientSymbolID: Set<ClientSymbolID>] {
        var map: [ClientSymbolID: Set<ClientSymbolID>] = [:]
        for symbol in graph.symbols {
            _ = map[symbol.id, default: []]
        }
        for dependency in graph.dependencies {
            map[dependency.from, default: []].insert(dependency.to)
            _ = map[dependency.to, default: []]
        }
        for component in graph.components {
            for symbol in component.entrySymbols {
                _ = map[symbol, default: []]
            }
        }
        for symbol in graph.runtimeSymbols {
            _ = map[symbol, default: []]
        }
        return map
    }

    private func stronglyConnectedSymbolGroups(
        symbols: [ClientSymbolID],
        dependencyMap: [ClientSymbolID: Set<ClientSymbolID>]
    ) -> [[ClientSymbolID]] {
        var state = StronglyConnectedState()
        for symbol in symbols.sorted() where state.indices[symbol] == nil {
            visit(
                symbol,
                dependencyMap: dependencyMap,
                state: &state
            )
        }
        return state.groups.sorted { left, right in
            guard let leftFirst = left.first, let rightFirst = right.first else {
                return left.count < right.count
            }
            return leftFirst < rightFirst
        }
    }

    private func visit(
        _ symbol: ClientSymbolID,
        dependencyMap: [ClientSymbolID: Set<ClientSymbolID>],
        state: inout StronglyConnectedState
    ) {
        state.indices[symbol] = state.nextIndex
        state.lowLinks[symbol] = state.nextIndex
        state.nextIndex += 1
        state.stack.append(symbol)
        state.stackMembership.insert(symbol)

        for dependency in dependencyMap[symbol, default: []].sorted() {
            if state.indices[dependency] == nil {
                visit(dependency, dependencyMap: dependencyMap, state: &state)
                let currentLowLink = state.lowLinks[symbol] ?? 0
                let dependencyLowLink = state.lowLinks[dependency] ?? 0
                state.lowLinks[symbol] = Swift.min(currentLowLink, dependencyLowLink)
            } else if state.stackMembership.contains(dependency) {
                let currentLowLink = state.lowLinks[symbol] ?? 0
                let dependencyIndex = state.indices[dependency] ?? 0
                state.lowLinks[symbol] = Swift.min(currentLowLink, dependencyIndex)
            }
        }

        guard state.lowLinks[symbol] == state.indices[symbol] else {
            return
        }

        var group: [ClientSymbolID] = []
        while let member = state.stack.popLast() {
            state.stackMembership.remove(member)
            group.append(member)
            if member == symbol {
                break
            }
        }
        state.groups.append(group.sorted())
    }

    private func allSymbols(
        in graph: ClientSymbolGraph,
        dependencyMap: [ClientSymbolID: Set<ClientSymbolID>]
    ) -> [ClientSymbolID] {
        var symbols = Set(graph.symbols.map { $0.id })
        symbols.formUnion(dependencyMap.keys)
        for dependencies in dependencyMap.values {
            symbols.formUnion(dependencies)
        }
        for component in graph.components {
            symbols.formUnion(component.entrySymbols)
        }
        symbols.formUnion(graph.runtimeSymbols)
        return symbols.sorted()
    }

    private func makeSymbolToGroup(_ groups: [[ClientSymbolID]]) -> [ClientSymbolID: Int] {
        var result: [ClientSymbolID: Int] = [:]
        for (index, group) in groups.enumerated() {
            for symbol in group {
                result[symbol] = index
            }
        }
        return result
    }

    private func makeGroupDependencies(
        groups: [[ClientSymbolID]],
        symbolToGroup: [ClientSymbolID: Int],
        dependencyMap: [ClientSymbolID: Set<ClientSymbolID>]
    ) -> [Int: Set<Int>] {
        var result: [Int: Set<Int>] = [:]
        for index in groups.indices {
            result[index] = []
        }
        for (symbol, dependencies) in dependencyMap {
            guard let group = symbolToGroup[symbol] else {
                continue
            }
            for dependency in dependencies {
                guard let dependencyGroup = symbolToGroup[dependency], dependencyGroup != group else {
                    continue
                }
                result[group, default: []].insert(dependencyGroup)
            }
        }
        return result
    }

    private func reachableGroups(
        from symbols: [ClientSymbolID],
        symbolToGroup: [ClientSymbolID: Int],
        groupDependencies: [Int: Set<Int>]
    ) -> Set<Int> {
        let roots = symbols.compactMap { symbol in
            symbolToGroup[symbol]
        }
        return reachableGroups(fromGroups: Set(roots), groupDependencies: groupDependencies)
    }

    private func reachableGroups(
        fromGroups roots: Set<Int>,
        groupDependencies: [Int: Set<Int>]
    ) -> Set<Int> {
        var visited: Set<Int> = []
        var stack = Array(roots).sorted()
        while let group = stack.popLast() {
            guard visited.insert(group).inserted else {
                continue
            }
            let dependencies = groupDependencies[group, default: []].sorted()
            stack.append(contentsOf: dependencies)
        }
        return visited
    }

    private func makeComponentGroups(
        _ components: [ClientComponentEntrypoint],
        symbolToGroup: [ClientSymbolID: Int],
        groupDependencies: [Int: Set<Int>]
    ) -> [ComponentID: Set<Int>] {
        var result: [ComponentID: Set<Int>] = [:]
        for component in components {
            result[component.componentID] = reachableGroups(
                from: component.entrySymbols,
                symbolToGroup: symbolToGroup,
                groupDependencies: groupDependencies
            )
        }
        return result
    }

    private func sharedGroups(
        componentGroups: [ComponentID: Set<Int>],
        excluding runtimeGroups: Set<Int>
    ) -> Set<Int> {
        var useCounts: [Int: Int] = [:]
        for groups in componentGroups.values {
            for group in groups where !runtimeGroups.contains(group) {
                useCounts[group, default: 0] += 1
            }
        }
        return Set(useCounts.compactMap { group, count in
            count >= options.sharedSymbolMinimumUseCount ? group : nil
        })
    }

    private func eagerRouteGroups(
        components: [ClientComponentEntrypoint],
        componentGroups: [ComponentID: Set<Int>],
        runtimeGroups: Set<Int>,
        sharedGroups: Set<Int>
    ) -> Set<Int> {
        var result: Set<Int> = []
        for component in components where component.loadPolicy == .eager {
            result.formUnion(componentGroups[component.componentID, default: []])
        }
        result.subtract(runtimeGroups)
        result.subtract(sharedGroups)
        return result
    }

    private func makeSymbolToBundle(
        bundles: [BundleDraft],
        groups: [[ClientSymbolID]]
    ) -> [ClientSymbolID: ClientBundleID] {
        var result: [ClientSymbolID: ClientBundleID] = [:]
        for bundle in bundles {
            for group in bundle.groups {
                for symbol in groups[group] {
                    result[symbol] = bundle.id
                }
            }
        }
        return result
    }

    private func makeBundleRecord(
        _ bundle: BundleDraft,
        groups: [[ClientSymbolID]],
        symbolSizes: [ClientSymbolID: Int],
        symbolToBundle: [ClientSymbolID: ClientBundleID],
        dependencyMap: [ClientSymbolID: Set<ClientSymbolID>]
    ) -> ClientBundleRecord {
        let symbols = symbols(in: bundle.groups, groups: groups)
        var dependencies: Set<ClientBundleID> = []
        for symbol in symbols {
            for dependency in dependencyMap[symbol, default: []] {
                guard let dependencyBundle = symbolToBundle[dependency], dependencyBundle != bundle.id else {
                    continue
                }
                dependencies.insert(dependencyBundle)
            }
        }
        if bundle.kind != .runtime, symbolToBundle.values.contains(options.runtimeBundleID) {
            dependencies.insert(options.runtimeBundleID)
        }
        return ClientBundleRecord(
            id: bundle.id,
            kind: bundle.kind,
            asset: bundle.asset,
            symbols: symbols,
            dependencies: Array(dependencies),
            components: bundle.components,
            loadPolicy: bundle.loadPolicy,
            estimatedByteSize: symbols.reduce(0) { total, symbol in
                total + symbolSizes[symbol, default: 0]
            }
        )
    }

    private func makeComponentAssets(
        _ components: [ClientComponentEntrypoint],
        componentGroups: [ComponentID: Set<Int>],
        symbolToBundle: [ClientSymbolID: ClientBundleID],
        runtimeGroups: Set<Int>,
        sharedGroups: Set<Int>,
        eagerGroups: Set<Int>
    ) -> [ClientComponentAsset] {
        components.map { component in
            ClientComponentAsset(
                componentID: component.componentID,
                typeName: component.typeName,
                bundleID: primaryBundleID(
                    for: component,
                    componentGroups: componentGroups[component.componentID, default: []],
                    symbolToBundle: symbolToBundle,
                    runtimeGroups: runtimeGroups,
                    sharedGroups: sharedGroups,
                    eagerGroups: eagerGroups
                ),
                loadPolicy: component.loadPolicy,
                entrySymbols: component.entrySymbols,
                serverSlots: component.serverSlots
            )
        }
    }

    private func primaryBundleID(
        for component: ClientComponentEntrypoint,
        componentGroups: Set<Int>,
        symbolToBundle: [ClientSymbolID: ClientBundleID],
        runtimeGroups: Set<Int>,
        sharedGroups: Set<Int>,
        eagerGroups: Set<Int>
    ) -> ClientBundleID {
        if component.loadPolicy == .eager, !eagerGroups.isDisjoint(with: componentGroups) {
            return options.eagerRouteBundleID
        }
        let componentBundle = componentBundleID(for: component)
        if symbolToBundle.values.contains(componentBundle) {
            return componentBundle
        }
        if !sharedGroups.isDisjoint(with: componentGroups) {
            return options.sharedBundleID
        }
        if !runtimeGroups.isDisjoint(with: componentGroups) {
            return options.runtimeBundleID
        }
        return component.loadPolicy == .eager ? options.eagerRouteBundleID : componentBundle
    }

    private func symbols(in groupIDs: Set<Int>, groups: [[ClientSymbolID]]) -> [ClientSymbolID] {
        groupIDs.sorted().flatMap { group in
            groups[group]
        }.sorted()
    }

    private func componentBundleID(for component: ClientComponentEntrypoint) -> ClientBundleID {
        ClientBundleID("component:\(stableHashHex("\(component.typeName)|\(component.componentID.rawValue)"))")
    }

    private func stableHashHex(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}

private struct BundleDraft {
    let id: ClientBundleID
    let kind: ClientBundleKind
    let groups: Set<Int>
    let components: [ComponentID]
    let loadPolicy: ClientLoadPolicy
    let asset: WasmAsset?

    init(
        id: ClientBundleID,
        kind: ClientBundleKind,
        groups: Set<Int>,
        components: [ComponentID],
        loadPolicy: ClientLoadPolicy,
        asset: WasmAsset? = nil
    ) {
        self.id = id
        self.kind = kind
        self.groups = groups
        self.components = components
        self.loadPolicy = loadPolicy
        self.asset = asset
    }
}

private struct StronglyConnectedState {
    var nextIndex = 0
    var indices: [ClientSymbolID: Int] = [:]
    var lowLinks: [ClientSymbolID: Int] = [:]
    var stack: [ClientSymbolID] = []
    var stackMembership = Set<ClientSymbolID>()
    var groups: [[ClientSymbolID]] = []
}
