import SwiftHTML
import Dispatch
import Synchronization
import Testing

private final class RenderBarrier: Sendable {
    let entered = DispatchSemaphore(value: 0)
    let resume = DispatchSemaphore(value: 0)
    private let armed = Mutex(false)
    func arm() { armed.withLock { $0 = true } }
    func waitForEntry() -> DispatchTimeoutResult { entered.wait(timeout: .now() + 5) }
    func pauseOnce() {
        let shouldPause = armed.withLock { value in
            let result = value
            value = false
            return result
        }
        if shouldPause {
            entered.signal()
            precondition(resume.wait(timeout: .now() + 5) == .success)
        }
    }
}

private struct ConcurrentProjection: ClientComponent {
    let store: StateStore
    let barrier: RenderBarrier
    var content: some Component {
        let _ = barrier.pauseOnce()
        let first: Int = store.value(for: StateSlotID("first"), default: 0)
        let second: Int = store.value(for: StateSlotID("second"), default: 0)
        output { "\(first):\(second)" }
    }
}

private struct TransactionCounter: ClientComponent {
    @State private var first = 0
    @State private var second = 0

    var content: some Component {
        button(.onClick {
            let transaction = Transaction()
            transaction.animation = TransactionAnimation(css: "1s linear 0s", durationMilliseconds: 1000)
            Transaction.withValue(transaction) { first += 1 }
            second += 1
        }) { "Update" }
        output { "\(first):\(second)" }
    }
}

private struct RevisionValue: Equatable, Sendable {
    let number: Int
}

private struct RevisionScope: Component {
    typealias Content = Never
    let value: RevisionValue

    static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        let revision = builder.valueRevision(html.value)
        return Element._buildNode(Element("span", attributes: [.data("revision", "\(revision)")]) {}, in: &builder)
    }
}

private struct ExternalAttributeCounter: ClientComponent {
    let state: State<Int>
    let trigger: HTMLAttribute
    var content: some Component {
        button(trigger) { "External \(state.wrappedValue)" }
    }
}

private final class ObservationCount: Sendable {
    private let count = Mutex(0)
    func increment() { count.withLock { $0 += 1 } }
    var value: Int { count.withLock { $0 } }
}

private struct RenderObservation: ClientComponent {
    @State private var first = 0
    @State private var second = 0
    @State private var observed = 0
    let observations: ObservationCount
    var content: some Component {
        let _ = observe()
        button(.onClick {
            let transaction = Transaction()
            transaction.animation = TransactionAnimation(css: "1s linear 0s", durationMilliseconds: 1000)
            Transaction.withValue(transaction) { first += 1 }
            second += 1
        }) { "Update" }
        output { "\(first):\(second)" }
    }
    private func observe() {
        if observed != first {
            observations.increment()
            observed = first
        }
    }
}

@Suite struct SwiftHTMLTransactionTests {
    @Test func renderOwnedObservationRunsOnceAcrossMutationGroups() throws {
        let observations = ObservationCount()
        var session = try HydrationRuntimeSession(root: RenderObservation(observations: observations))
        let handler = try #require(session.artifact.clientHandlers.handlers.first)
        let update = try session.invoke(handlerID: handler.id)
        #expect(update.html.contains("1:1"))
        #expect(observations.value == 1)
    }
    @Test func mountedHandlerOwnsAttributesCreatedBeforeRendering() throws {
        let state = State(wrappedValue: 0)
        let trigger = HTMLAttribute.onClick { state.wrappedValue += 1 }
        var session = try HydrationRuntimeSession(root: ExternalAttributeCounter(state: state, trigger: trigger))
        let handler = try #require(session.artifact.clientHandlers.handlers.first)
        let update = try session.invoke(handlerID: handler.id)
        #expect(update.html.contains("External 1"))
        #expect(update.steps.count == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func concurrentMutationDoesNotLeakIntoCapturedProjectionOrLoseInvalidation() async throws {
        let store = StateStore()
        let barrier = RenderBarrier()
        let session = try HydrationRuntimeSession(root: ConcurrentProjection(store: store, barrier: barrier), stateStore: store)
        let owner = ComponentID("owner")
        store.set(1, for: StateSlotID("first"), componentID: owner)
        barrier.arm()
        let task = Task.detached {
            var owned = session
            let update = try owned.flush()
            return (owned, update)
        }
        let entered = await Task.detached { barrier.waitForEntry() }.value
        #expect(entered == .success)
        store.set(99, for: StateSlotID("second"), componentID: owner)
        barrier.resume.signal()
        var (resumed, first) = try await task.value
        #expect(first.html.contains("1:0"))
        #expect(!store.dirtyComponents().isEmpty)
        let second = try resumed.flush()
        #expect(second.html.contains("1:99"))
        #expect(store.dirtyComponents().isEmpty)
    }

    @Test func capturesMutationTimingWithoutAnimatingOtherState() throws {
        var session = try HydrationRuntimeSession(root: TransactionCounter())
        let handler = try #require(session.artifact.clientHandlers.handlers.first)
        let update = try session.invoke(handlerID: handler.id)
        #expect(update.steps.count == 2)
        #expect(update.steps[0].animation?.durationMilliseconds == 1000)
        #expect(update.steps[1].animation == nil)
        #expect(update.steps[0].commandBatch.commands.contains { command in
            if case .updateText(_, "1:0") = command { return true }
            return false
        })
        #expect(update.steps[1].commandBatch.commands.contains { command in
            if case .updateText(_, "1:1") = command { return true }
            return false
        })
        #expect(update.steps[0].hydrationIndex == update.steps[1].previousHydrationIndex)
        #expect(update.html.contains("1:1"))
        let next = try session.invoke(handlerID: handler.id)
        #expect(next.html.contains("2:2"))
        #expect(next.steps.count == 2)
        #expect(try session.flush().steps.isEmpty)
    }

    @Test func comparesWithoutCodableAndResetsRemovedIdentity() throws {
        let renderer = HTMLRenderer()
        let store = StateStore()
        let first = renderer.render(RevisionScope(value: RevisionValue(number: 1)), stateStore: store)
        let same = renderer.render(RevisionScope(value: RevisionValue(number: 1)), stateStore: store)
        let changed = renderer.render(RevisionScope(value: RevisionValue(number: 2)), stateStore: store)
        #expect(first.html.contains("data-revision=\"0\""))
        #expect(same.html == first.html)
        #expect(changed.html.contains("data-revision=\"1\""))
        #expect(try store.snapshot(schemaHash: "test").values.isEmpty)
        _ = renderer.render(text("removed"), stateStore: store)
        let reinserted = renderer.render(RevisionScope(value: RevisionValue(number: 2)), stateStore: store)
        #expect(reinserted.html.contains("data-revision=\"0\""))
    }
}
