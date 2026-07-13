#if !os(WASI)
// The enlarged-stack worker below requires `Thread` and `DispatchSemaphore`,
// which FoundationEssentials does not provide — import full Foundation and
// Dispatch on every non-WASI platform (including static Linux, where
// FoundationEssentials is also importable but insufficient).
import Foundation
#if canImport(Dispatch)
import Dispatch
#endif
#endif

public protocol EnlargedStackContextPropagator: Sendable {
    func apply<Result>(_ operation: () throws -> Result) rethrows -> Result
}

public enum EnlargedStackContext {
    @TaskLocal public static var propagators: [any EnlargedStackContextPropagator] = []

    public static func withValue<Result>(
        _ propagator: any EnlargedStackContextPropagator,
        operation: () throws -> Result
    ) rethrows -> Result {
        try $propagators.withValue(propagators + [propagator], operation: operation)
    }

    public static func withValue<Result>(
        _ propagator: any EnlargedStackContextPropagator,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        try await $propagators.withValue(propagators + [propagator], operation: operation)
    }

    static func apply<Result>(
        _ propagators: [any EnlargedStackContextPropagator],
        operation: () throws -> Result
    ) rethrows -> Result {
        try apply(propagators[...], operation: operation)
    }

    private static func apply<Result>(
        _ propagators: ArraySlice<any EnlargedStackContextPropagator>,
        operation: () throws -> Result
    ) rethrows -> Result {
        guard let first = propagators.first else {
            return try operation()
        }
        return try first.apply {
            try apply(propagators.dropFirst(), operation: operation)
        }
    }
}

#if os(WASI)

/// Runs `work` directly. WebAssembly is single-threaded and has no `Thread` or
/// `DispatchSemaphore`, so the enlarged-stack worker is neither available nor
/// needed: the WASM module's main stack is sized at instantiation, which is where
/// deep type-metadata recursion is accommodated.
func withEnlargedStack<Result>(
    ofSize stackSize: Int = 64 << 20,
    _ work: @escaping () -> Result
) -> Result {
    EnlargedStackContext.apply(EnlargedStackContext.propagators) {
        work()
    }
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
    let propagators = EnlargedStackContext.propagators
    let thread = StackBoundThread(stackSize: stackSize) {
        // Always signal, even if `work()` exits abnormally, so the calling thread
        // can never park forever: a failure surfaces as the `box.take()`
        // precondition rather than a silent deadlock of the render path.
        defer { semaphore.signal() }
        box.value = EnlargedStackContext.apply(propagators) {
            work()
        }
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
