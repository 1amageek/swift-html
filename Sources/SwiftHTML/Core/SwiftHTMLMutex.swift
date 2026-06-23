#if hasFeature(Embedded)
final class SwiftHTMLMutex<Value>: Sendable {
    nonisolated(unsafe) private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withLock<Result>(_ operation: (inout Value) throws -> Result) rethrows -> Result {
        try operation(&value)
    }
}
#else
import Synchronization

typealias SwiftHTMLMutex<Value> = Mutex<Value>
#endif
