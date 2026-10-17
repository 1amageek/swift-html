public struct HydrationRuntimeUpdate: Sendable, Equatable {
    public let dirtyComponents: [ComponentID]
    public let patches: [HTMLPatch]
    public let commandBatch: BrowserDOMCommandBatch
    public let previousHydrationIndex: BrowserHydrationIndex
    public let hydrationIndex: BrowserHydrationIndex
    public let html: String
    public let steps: [HydrationRuntimeStep]

    public init(
        dirtyComponents: [ComponentID],
        patches: [HTMLPatch],
        commandBatch: BrowserDOMCommandBatch = BrowserDOMCommandBatch(commands: []),
        previousHydrationIndex: BrowserHydrationIndex = .empty,
        hydrationIndex: BrowserHydrationIndex = .empty,
        html: String,
        steps: [HydrationRuntimeStep] = []
    ) {
        self.dirtyComponents = dirtyComponents
        self.patches = patches
        self.commandBatch = commandBatch
        self.previousHydrationIndex = previousHydrationIndex
        self.hydrationIndex = hydrationIndex
        self.html = html
        self.steps = steps
    }

    public var commands: [BrowserDOMCommand] {
        commandBatch.commands
    }
}
