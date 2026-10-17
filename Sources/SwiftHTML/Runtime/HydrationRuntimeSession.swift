public struct HydrationRuntimeSession<Root: Component>: Sendable {
    public let root: Root
    public var environment: EnvironmentValues
    public let stateStore: StateStore
    public let options: HTMLRenderOptions
    public private(set) var artifact: RenderArtifact
    public private(set) var dom: HTMLDOMSnapshot

    // The browser hydration index is a pure function of `artifact`, and the
    // "previous" index of one flush is the "next" index of the prior flush.
    // Caching it (refreshed only when `artifact` changes) collapses the two full
    // O(N) index exports per flush down to one.
    private var cachedHydrationIndex: BrowserHydrationIndex

    private let renderer = HTMLRenderer()
    private let applicator = HTMLDOMPatchApplicator()
    private let commandEncoder = BrowserDOMCommandEncoder()

    public init(
        root: Root,
        environment: EnvironmentValues = EnvironmentValues(),
        stateStore: StateStore = StateStore(),
        options: HTMLRenderOptions = .development
    ) throws {
        self.root = root
        self.environment = environment
        self.stateStore = stateStore
        self.options = options
        let artifact = renderer.render(
            root,
            environment: environment,
            stateStore: stateStore,
            options: options
        )
        try artifact.validateHydration()
        self.artifact = artifact
        self.dom = HTMLDOMSnapshot(graph: artifact.graph, rootID: artifact.rootID)
        self.cachedHydrationIndex = artifact.browserHydrationIndex()
        stateStore.recordMutations()
    }

    public mutating func invoke(
        handlerID: HandlerID,
        event: DOMEvent = DOMEvent()
    ) throws -> HydrationRuntimeUpdate {
        guard let handler = artifact.clientHandlers.handlers.first(where: { $0.id == handlerID }) else {
            throw HydrationRuntimeError.missingHandler(handlerID)
        }

        handler.invoke(with: event)
        return try flush()
    }

    public mutating func flush() throws -> HydrationRuntimeUpdate {
        let dirtyComponents = stateStore.dirtyComponents().sorted { left, right in
            left.rawValue < right.rawValue
        }
        let previousHydrationIndex = cachedHydrationIndex
        guard !dirtyComponents.isEmpty else {
            return HydrationRuntimeUpdate(
                dirtyComponents: [],
                patches: [],
                commandBatch: BrowserDOMCommandBatch(commands: []),
                previousHydrationIndex: previousHydrationIndex,
                hydrationIndex: previousHydrationIndex,
                html: dom.html
            )
        }

        let pending = stateStore.pendingUpdate()
        let mutations = pending.mutations
        let comparisons = stateStore.comparisonSnapshot()
        var didCommit = false
        defer {
            if !didCommit { stateStore.restoreComparisons(comparisons) }
        }
        var projection = StateStore.ReadProjection(owner: stateStore, values: pending.values, absent: [])
        for mutation in mutations.reversed() {
            if let previous = mutation.previous {
                projection.values[mutation.id] = previous
                projection.absent.remove(mutation.id)
            } else {
                projection.values.removeValue(forKey: mutation.id)
                projection.absent.insert(mutation.id)
            }
        }
        var nextArtifact = artifact
        let renderWrites = StateStore.RenderWrites(owner: stateStore)
        var steps: [HydrationRuntimeStep] = []
        var cursor = 0
        repeat {
            let animation = cursor < mutations.count ? mutations[cursor].animation : nil
            while cursor < mutations.count && mutations[cursor].animation == animation {
                let mutation = mutations[cursor]
                projection.values[mutation.id] = mutation.value
                projection.absent.remove(mutation.id)
                cursor += 1
            }
            let rendered = StateStore.$renderWrites.withValue(renderWrites) {
                StateStore.$readProjection.withValue(projection) {
                    renderer.render(root, environment: environment, stateStore: stateStore, options: options)
                }
            }
            for (id, value) in renderWrites.consume() {
                projection.values[id] = value
                projection.absent.remove(id)
            }
            try rendered.validateHydration()
            let stepPatches = HTMLDiffer(renderOptions: options).diff(from: nextArtifact, to: rendered)
            steps.append(HydrationRuntimeStep(
                commandBatch: commandEncoder.encode(stepPatches),
                previousHydrationIndex: nextArtifact.browserHydrationIndex(),
                hydrationIndex: rendered.browserHydrationIndex(),
                animation: animation
            ))
            nextArtifact = rendered
        } while cursor < mutations.count
        let patches = HTMLDiffer(renderOptions: options).diff(from: artifact, to: nextArtifact)
        let commandBatch = commandEncoder.encode(patches)
        _ = try applicator.apply(patches, to: dom)
        dom = HTMLDOMSnapshot(graph: nextArtifact.graph, rootID: nextArtifact.rootID)
        artifact = nextArtifact
        let nextHydrationIndex = nextArtifact.browserHydrationIndex()
        cachedHydrationIndex = nextHydrationIndex
        stateStore.consumeMutations(mutations.count, clearing: dirtyComponents)
        didCommit = true

        return HydrationRuntimeUpdate(
            dirtyComponents: dirtyComponents,
            patches: patches,
            commandBatch: commandBatch,
            previousHydrationIndex: previousHydrationIndex,
            hydrationIndex: nextHydrationIndex,
            html: dom.html,
            steps: steps
        )
    }
}
