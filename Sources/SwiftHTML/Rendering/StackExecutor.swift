#if !os(WASI)
import Foundation
#endif

#if os(WASI)

/// Runs `work` directly. WebAssembly is single-threaded and has no `Thread` or
/// `DispatchSemaphore`, so the enlarged-stack worker is neither available nor
/// needed: the WASM module's main stack is sized at instantiation, which is where
/// deep type-metadata recursion is accommodated.
func withEnlargedStack<Result>(
    ofSize stackSize: Int = 64 << 20,
    _ work: @escaping () -> Result
) -> Result {
    work()
}

#else

/// Runs `work` on a dedicated thread with an enlarged stack and returns its
/// result synchronously.
///
/// HTML graph construction recurses through the *concrete* generic type of the
/// component tree: a deeply composed tree (nested containers and modifier
/// chains) produces a deeply nested concrete type, and the Swift runtime's
/// type-metadata decoder recurses far enough to overflow the default thread
/// stack while instantiating it. Building the graph on a thread with a generous
/// stack gives that decoding the room it needs, so the component type
/// architecture stays fully statically typed.
///
/// The call is a synchronous baton: the calling thread blocks on the semaphore
/// until the worker finishes, so `work` and its result are never accessed
/// concurrently. This makes the non-`Sendable` hand-off safe by construction.
func withEnlargedStack<Result>(
    ofSize stackSize: Int = 64 << 20,
    _ work: @escaping () -> Result
) -> Result {
    let box = StackResultBox<Result>()
    let semaphore = DispatchSemaphore(value: 0)
    let thread = StackBoundThread(stackSize: stackSize) {
        // Always signal, even if `work()` exits abnormally, so the calling thread
        // can never park forever: a failure surfaces as the `box.take()`
        // precondition rather than a silent deadlock of the render path.
        defer { semaphore.signal() }
        box.value = work()
    }
    thread.start()
    semaphore.wait()
    return box.take()
}

private final class StackResultBox<Result> {
    var value: Result?

    func take() -> Result {
        guard let value else {
            preconditionFailure("Enlarged-stack worker finished without producing a result")
        }
        return value
    }
}

private final class StackBoundThread: Thread {
    private let work: () -> Void

    init(stackSize: Int, work: @escaping () -> Void) {
        self.work = work
        super.init()
        self.stackSize = stackSize
    }

    override func main() {
        work()
    }
}

#endif
