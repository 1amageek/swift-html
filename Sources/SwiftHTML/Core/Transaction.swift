import Synchronization

/// The already-lowered presentation timing an explicit transaction wants the
/// changes it produces to be interpolated with: the CSS `transition` timing tail
/// (`<duration> <timing-function> <delay>`) plus the total duration the runtime
/// needs in order to know when the animation is finished.
///
/// The rich, SwiftUI-shaped animation type that lowers to this lives in the
/// presentation layer; the reactivity layer only ever sees this resolved form, so
/// it stays unaware of how animations are described.
public struct TransactionAnimation: Sendable, Equatable {
    public let css: String
    public let durationMilliseconds: Int

    public init(css: String, durationMilliseconds: Int) {
        self.css = css
        self.durationMilliseconds = durationMilliseconds
    }
}

/// A synchronous mutation context. StateStore captures a value snapshot of its
/// animation at each mutation. Scoped entry points bind a fresh instance and
/// restore the caller's context on return or throw; render/DOM timing is not
/// inferred from whichever transaction happens to be current at event completion.
public final class Transaction: Sendable {
    private let storage = SwiftHTMLMutex<TransactionAnimation?>(nil)

    public init() {}

    public var animation: TransactionAnimation? {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }

    @TaskLocal public static var current: Transaction?

    public static func withValue<Result>(
        _ value: Transaction?,
        operation: () throws -> Result
    ) rethrows -> Result {
        try $current.withValue(value, operation: operation)
    }
}
