import Synchronization
import SwiftHTML
#if os(WASI)
import WASILibc
#endif

nonisolated private func checkpoint(_ message: String) {
    print(message)
    #if os(WASI)
    fflush(nil)
    #endif
}

private struct TimedCounter: ClientComponent {
    @State private var animated = 0
    @State private var plain = 0
    @State private var observed = 0
    let observations: NotificationCounter

    var content: some Component {
        let _ = observe()
        button(.onClick {
            let transaction = Transaction()
            transaction.animation = TransactionAnimation(css: "1s linear 0s", durationMilliseconds: 1000)
            Transaction.withValue(transaction) { animated += 1 }
            plain += 1
        }) { "Update" }
        output { "\(animated):\(plain)" }
    }

    private func observe() {
        if observed != animated {
            observations.append(ComponentID("change"))
            observed = animated
        }
    }
}

private struct ComparedValue: Equatable, Sendable { let number: Int }

private struct ComparedScope: Component {
    typealias Content = Never
    let value: ComparedValue
    static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        let revision = builder.valueRevision(html.value)
        return Element._buildNode(Element("span", attributes: [.data("revision", "\(revision)")]) {}, in: &builder)
    }
}

private final class NotificationCounter: Sendable {
    private let storage = Mutex<[ComponentID]>([])

    func append(_ componentID: ComponentID) {
        storage.withLock { values in
            values.append(componentID)
        }
    }

    func values() -> [ComponentID] {
        storage.withLock { $0 }
    }
}

@main
struct Validation {
    static func main() throws {
        try verifyState()
    }

    nonisolated private static func verifyState() throws {
        checkpoint("state verification started")
        let slotID = StateSlotID("optional-slot")
        let componentID = ComponentID("optional-component")
        let store = StateStore()
        let notifications = NotificationCounter()

        store.setInvalidationHandler { notifiedComponentID in
            precondition(store.dirtyComponents().contains(notifiedComponentID))
            notifications.append(notifiedComponentID)
        }

        let initial: String? = store.value(for: slotID, default: nil)
        precondition(initial == nil)
        let storedNilWins: String? = store.value(for: slotID, default: "Fallback")
        precondition(storedNilWins == nil)

        store.set("Alice" as String?, for: slotID, componentID: componentID)
        let updated: String? = store.value(for: slotID, default: nil)
        precondition(updated == "Alice")
        precondition(store.dirtyComponents() == [componentID])
        precondition(notifications.values() == [componentID])

        store.set("Bob" as String?, for: slotID, componentID: componentID)
        let replaced: String? = store.value(for: slotID, default: nil)
        precondition(replaced == "Bob")
        precondition(notifications.values() == [componentID])

        store.clearDirtyComponents([componentID])
        store.set(nil as String?, for: slotID, componentID: componentID)
        let cleared: String? = store.value(for: slotID, default: "Fallback")
        precondition(cleared == nil)
        precondition(store.dirtyComponents() == [componentID])
        precondition(notifications.values() == [componentID, componentID])

        store.setInvalidationHandler(nil)

        let localState = State<String?>(wrappedValue: nil)
        precondition(localState.wrappedValue == nil)
        localState.wrappedValue = "Local"
        precondition(localState.wrappedValue == "Local")
        localState.wrappedValue = nil
        precondition(localState.wrappedValue == nil)

        checkpoint("optional state verified")
        let observations = NotificationCounter()
        var session = try HydrationRuntimeSession(root: TimedCounter(observations: observations))
        checkpoint("transaction session initialized")
        precondition(session.artifact.hydration.components.first?.stateSlots.count == 3)
        guard let handler = session.artifact.clientHandlers.handlers.first else {
            preconditionFailure("Missing counter event binding")
        }
        handler.invoke()
        let update = try session.flush()
        precondition(observations.values().count == 1)
        precondition(update.steps.count == 2)
        precondition(update.steps[0].animation?.durationMilliseconds == 1000)
        precondition(update.steps[1].animation == nil)
        precondition(update.commands.contains {
            if case .updateText(_, "1:1") = $0 { return true }
            return false
        })
        precondition(update.steps[0].hydrationIndex == update.steps[1].previousHydrationIndex)
        let next = try session.invoke(handlerID: handler.id)
        precondition(observations.values().count == 2)
        checkpoint("second transaction reconciled")
        precondition(next.commands.contains {
            if case .updateText(_, "2:2") = $0 { return true }
            return false
        })
        let empty = try session.flush()
        precondition(empty.steps.isEmpty)
        checkpoint("transaction state verified")

        let comparisonStore = StateStore()
        let renderer = HTMLRenderer()
        let first = renderer.render(ComparedScope(value: ComparedValue(number: 1)), stateStore: comparisonStore)
        checkpoint("first comparison rendered")
        let same = renderer.render(ComparedScope(value: ComparedValue(number: 1)), stateStore: comparisonStore)
        let changed = renderer.render(ComparedScope(value: ComparedValue(number: 2)), stateStore: comparisonStore)
        checkpoint("changed comparison rendered")
        precondition(first.html == same.html)
        precondition(first.html != changed.html)
        let unchanged = renderer.render(ComparedScope(value: ComparedValue(number: 2)), stateStore: comparisonStore)
        precondition(unchanged.html == changed.html)

        print("swift-html optional state passed")
        print("swift-html mutation transactions passed")
    }
}
