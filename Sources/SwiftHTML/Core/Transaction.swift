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

/// A per-update context that travels from a state mutation to the update it
/// produces, mirroring SwiftUI's `Transaction`. `withAnimation`-style entry points
/// set its `animation`; the runtime reads it when it applies that update's DOM
/// changes. It belongs to the reactivity layer but stays presentation-agnostic by
/// carrying only the already-lowered `TransactionAnimation`.
///
/// A fresh instance is bound per update (see `Transaction.$current`), so an
/// animation never leaks into a later, unrelated update.
public final class Transaction: Sendable {
    private let storage = Mutex<TransactionAnimation?>(nil)

    public init() {}

    public var animation: TransactionAnimation? {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }

    @TaskLocal public static var current: Transaction?
}
