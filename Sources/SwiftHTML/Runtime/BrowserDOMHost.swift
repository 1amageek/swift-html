public protocol BrowserDOMHost: Sendable {
    func apply(_ batch: BrowserDOMCommandBatch, currentIndex: BrowserHydrationIndex) throws

    /// Applies a batch whose changes an explicit transaction asked to be animated.
    /// Hosts that mutate the live DOM realize the animation; hosts that only
    /// collect or log commands have nothing to animate and use the default, which
    /// ignores it.
    func apply(
        _ batch: BrowserDOMCommandBatch,
        currentIndex: BrowserHydrationIndex,
        animation: TransactionAnimation?
    ) throws
}

public extension BrowserDOMHost {
    func apply(
        _ batch: BrowserDOMCommandBatch,
        currentIndex: BrowserHydrationIndex,
        animation: TransactionAnimation?
    ) throws {
        try apply(batch, currentIndex: currentIndex)
    }
}
