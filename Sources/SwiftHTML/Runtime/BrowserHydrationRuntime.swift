public struct BrowserHydrationRuntime<Root: HTML, Host: BrowserDOMHost> {
    public private(set) var session: HydrationRuntimeSession<Root>
    public let host: Host

    public var hydrationIndex: BrowserHydrationIndex {
        session.artifact.browserHydrationIndex()
    }

    public init(
        root: Root,
        host: Host,
        environment: EnvironmentValues = EnvironmentValues(),
        stateStore: StateStore = StateStore(),
        options: HTMLRenderOptions = .development
    ) throws {
        self.session = try HydrationRuntimeSession(
            root: root,
            environment: environment,
            stateStore: stateStore,
            options: options
        )
        self.host = host
    }

    public mutating func invoke(
        handlerID: HandlerID,
        event: DOMEvent = DOMEvent()
    ) throws -> HydrationRuntimeUpdate {
        let update = try session.invoke(handlerID: handlerID, event: event)
        try apply(update)
        return update
    }

    public mutating func flush() throws -> HydrationRuntimeUpdate {
        let update = try session.flush()
        try apply(update)
        return update
    }

    private func apply(_ update: HydrationRuntimeUpdate) throws {
        guard !update.commandBatch.isEmpty else {
            return
        }
        try host.apply(update.commandBatch, updatedIndex: update.hydrationIndex)
    }
}
