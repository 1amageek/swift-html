public struct HydrationRuntimeSession<Root: HTML> {
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

        let nextArtifact = renderer.render(
            root,
            environment: environment,
            stateStore: stateStore,
            options: options
        )
        try nextArtifact.validateHydration()
        let patches = HTMLDiffer(renderOptions: options).diff(from: artifact, to: nextArtifact)
        let commandBatch = commandEncoder.encode(patches)
        _ = try applicator.apply(patches, to: dom)
        dom = HTMLDOMSnapshot(graph: nextArtifact.graph, rootID: nextArtifact.rootID)
        artifact = nextArtifact
        let nextHydrationIndex = nextArtifact.browserHydrationIndex()
        cachedHydrationIndex = nextHydrationIndex
        stateStore.clearDirtyComponents(dirtyComponents)

        return HydrationRuntimeUpdate(
            dirtyComponents: dirtyComponents,
            patches: patches,
            commandBatch: commandBatch,
            previousHydrationIndex: previousHydrationIndex,
            hydrationIndex: nextHydrationIndex,
            html: dom.html
        )
    }
}
