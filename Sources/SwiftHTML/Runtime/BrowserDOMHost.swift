public protocol BrowserDOMHost: Sendable {
    func apply(_ batch: BrowserDOMCommandBatch, currentIndex: BrowserHydrationIndex) throws
}
