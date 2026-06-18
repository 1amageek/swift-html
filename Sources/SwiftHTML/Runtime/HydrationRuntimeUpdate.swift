public struct HydrationRuntimeUpdate: Sendable, Equatable {
    public let dirtyComponents: [ComponentID]
    public let patches: [HTMLPatch]
    public let commandBatch: BrowserDOMCommandBatch
    public let previousHydrationIndex: BrowserHydrationIndex
    public let hydrationIndex: BrowserHydrationIndex
    public let html: String

    public init(
        dirtyComponents: [ComponentID],
        patches: [HTMLPatch],
        commandBatch: BrowserDOMCommandBatch = BrowserDOMCommandBatch(commands: []),
        previousHydrationIndex: BrowserHydrationIndex = .empty,
        hydrationIndex: BrowserHydrationIndex = .empty,
        html: String
    ) {
        self.dirtyComponents = dirtyComponents
        self.patches = patches
        self.commandBatch = commandBatch
        self.previousHydrationIndex = previousHydrationIndex
        self.hydrationIndex = hydrationIndex
        self.html = html
    }

    public var commands: [BrowserDOMCommand] {
        commandBatch.commands
    }
}
