public protocol BrowserDOMHost: Sendable {
    func apply(_ batch: BrowserDOMCommandBatch, updatedIndex: BrowserHydrationIndex) throws
}
