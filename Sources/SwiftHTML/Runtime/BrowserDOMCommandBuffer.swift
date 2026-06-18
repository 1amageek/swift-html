import Synchronization

public final class BrowserDOMCommandBuffer: BrowserDOMHost {
    private let storage = Mutex([[BrowserDOMCommand]]())
    private let indexStorage = Mutex([BrowserHydrationIndex]())

    public init() {}

    public func apply(_ batch: BrowserDOMCommandBatch, currentIndex: BrowserHydrationIndex) {
        storage.withLock { batches in
            batches.append(batch.commands)
        }
        indexStorage.withLock { indexes in
            indexes.append(currentIndex)
        }
    }

    public func batches() -> [[BrowserDOMCommand]] {
        storage.withLock { batches in
            batches
        }
    }

    public func lastBatch() -> [BrowserDOMCommand]? {
        storage.withLock { batches in
            batches.last
        }
    }

    public func indexes() -> [BrowserHydrationIndex] {
        indexStorage.withLock { indexes in
            indexes
        }
    }

    public func lastIndex() -> BrowserHydrationIndex? {
        indexStorage.withLock { indexes in
            indexes.last
        }
    }
}
