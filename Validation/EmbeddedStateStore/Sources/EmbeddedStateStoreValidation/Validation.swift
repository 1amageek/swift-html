import Synchronization
import SwiftHTML

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
    static func main() {
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

        print("swift-html optional state passed")
    }
}
