import Synchronization

public final class BrowserDOMCommandBuffer: BrowserDOMHost {
    private struct State: Sendable {
        var batches: [[BrowserDOMCommand]] = []
        var indexes: [BrowserHydrationIndex] = []
    }

    private let state = SwiftHTMLMutex(State())

    public init() {}

    public func apply(_ batch: BrowserDOMCommandBatch, currentIndex: BrowserHydrationIndex) {
        state.withLock { state in
            state.batches.append(batch.commands)
            state.indexes.append(currentIndex)
        }
    }

    public func batches() -> [[BrowserDOMCommand]] {
        state.withLock { state in
            state.batches
        }
    }

    public func lastBatch() -> [BrowserDOMCommand]? {
        state.withLock { state in
            state.batches.last
        }
    }

    public func indexes() -> [BrowserHydrationIndex] {
        state.withLock { state in
            state.indexes
        }
    }

    public func lastIndex() -> BrowserHydrationIndex? {
        state.withLock { state in
            state.indexes.last
        }
    }
}
