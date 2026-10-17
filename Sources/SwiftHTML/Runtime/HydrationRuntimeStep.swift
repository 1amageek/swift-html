/// One ordered reconciliation boundary. Apply against previousHydrationIndex,
/// then adopt hydrationIndex before applying the next step.
public struct HydrationRuntimeStep: Sendable, Equatable {
    public let commandBatch: BrowserDOMCommandBatch
    public let previousHydrationIndex: BrowserHydrationIndex
    public let hydrationIndex: BrowserHydrationIndex
    public let animation: TransactionAnimation?

    public init(
        commandBatch: BrowserDOMCommandBatch,
        previousHydrationIndex: BrowserHydrationIndex,
        hydrationIndex: BrowserHydrationIndex,
        animation: TransactionAnimation?
    ) {
        self.commandBatch = commandBatch
        self.previousHydrationIndex = previousHydrationIndex
        self.hydrationIndex = hydrationIndex
        self.animation = animation
    }
}
