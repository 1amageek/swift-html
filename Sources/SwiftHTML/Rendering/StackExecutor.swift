import Synchronization

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

#if hasFeature(Embedded)
/// The Embedded profile does not use the enlarged-stack worker or its
/// existential propagator list. Individual render contexts still use
/// `@TaskLocal`; this wrapper runs the operation directly on the stack provided
/// by the selected Embedded platform implementation.
public enum EnlargedStackContext {
    public static func withValue<Result>(
        _ propagator: some EnlargedStackContextPropagator,
        operation: () throws -> Result
    ) rethrows -> Result {
        try operation()
    }

    public static func withValue<Result>(
        _ propagator: some EnlargedStackContextPropagator,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        try await operation()
    }
}
#else
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

#endif

#if os(WASI) || hasFeature(Embedded)

/// Runs `work` directly when the selected platform implementation does not
/// provide the Foundation thread worker used by the Native profile. The
/// deployment controls the available stack through its platform runtime.
func withEnlargedStack<Result: Sendable>(
    ofSize stackSize: Int = 64 << 20,
    _ work: sending @escaping () -> Result
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
/// The call is a synchronous ownership baton: `work` is transferred into a
/// once-only mutex-backed box, and the caller blocks until the worker stores a
/// `Sendable` result. User work and external callbacks run outside the locks.
func withEnlargedStack<Result: Sendable>(
    ofSize stackSize: Int = 64 << 20,
    _ work: sending @escaping () -> Result
) -> Result {
    let box = StackResultBox<Result>()
    let workBox = StackWorkBox(work)
    let semaphore = DispatchSemaphore(value: 0)
    let propagators = EnlargedStackContext.propagators
    let thread = Thread {
        // Always signal, even if `work()` exits abnormally, so the calling thread
        // can never park forever: a failure surfaces as the `box.take()`
        // precondition rather than a silent deadlock of the render path.
        defer { semaphore.signal() }
        box.store(EnlargedStackContext.apply(propagators) {
            workBox.takeAndRun()
        })
    }
    thread.stackSize = stackSize
    #if canImport(Darwin)
    thread.qualityOfService = .userInitiated
    #endif
    thread.start()
    semaphore.wait()
    return box.take()
}

private final class StackWorkBox<Result: Sendable>: Sendable {
    private let work: SwiftHTMLMutex<(() -> Result)?>

    init(_ work: sending @escaping () -> Result) {
        self.work = SwiftHTMLMutex(work)
    }

    func takeAndRun() -> Result {
        let operation = work.withLock { work in
            guard let operation = work else {
                preconditionFailure("Enlarged-stack work can only run once")
            }
            work = nil
            return operation
        }
        return operation()
    }
}

private final class StackResultBox<Result: Sendable>: Sendable {
    private let value = SwiftHTMLMutex<Result?>(nil)

    func store(_ result: Result) {
        value.withLock { value in
            value = result
        }
    }

    func take() -> Result {
        value.withLock { value in
            guard let result = value else {
                preconditionFailure("Enlarged-stack worker finished without producing a result")
            }
            return result
        }
    }
}

#endif
