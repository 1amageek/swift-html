import Foundation
import Synchronization

public struct StateSourceLocation: Sendable, Hashable, Codable {
    public let fileID: String
    public let line: UInt
    public let column: UInt

    public init(fileID: String, line: UInt, column: UInt) {
        self.fileID = fileID
        self.line = line
        self.column = column
    }

    public var rawValue: String {
        "\(fileID):\(line):\(column)"
    }
}

public struct StateSlotID: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(componentID: ComponentID, source: StateSourceLocation) {
        self.rawValue = "\(componentID.rawValue):state:\(source.rawValue)"
    }
}

public struct StateSlotRecord: Sendable, Codable, Equatable {
    public let id: StateSlotID
    public let componentID: ComponentID
    public let valueType: String
    public let source: StateSourceLocation

    public init(
        id: StateSlotID,
        componentID: ComponentID,
        valueType: String,
        source: StateSourceLocation
    ) {
        self.id = id
        self.componentID = componentID
        self.valueType = valueType
        self.source = source
    }
}

public final class StateStore: Sendable {
    private struct Storage: Sendable {
        var values: [StateSlotID: RuntimeValueBox] = [:]
        var valueTypes: [StateSlotID: String] = [:]
        var restoredValues: [StateSlotID: StateSnapshotValue] = [:]
        var dirtyComponents: Set<ComponentID> = []
    }

    private let storage = Mutex(Storage())

    public init() {}

    public func value<Value: Sendable>(
        for id: StateSlotID,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        let valueType = String(reflecting: Value.self)
        let lookup: (existing: Value?, restored: StateSnapshotValue?) = storage.withLock { storage in
            if let existing = storage.values[id]?.value(as: Value.self) {
                return (existing, nil)
            }

            if let restored = storage.restoredValues[id] {
                storage.restoredValues[id] = nil
                if restored.valueType == valueType {
                    return (nil, restored)
                }
            }

            return (nil, nil)
        }

        if let existing = lookup.existing {
            return existing
        }

        if let restored = lookup.restored,
           let restoredValue = Self.decodeRestoredValue(restored, as: Value.self) {
            return install(restoredValue, for: id, valueType: valueType)
        }

        return install(defaultValue(), for: id, valueType: valueType)
    }

    public func set<Value: Sendable>(
        _ value: Value,
        for id: StateSlotID,
        componentID: ComponentID
    ) {
        let valueType = String(reflecting: Value.self)
        storage.withLock { storage in
            storage.values[id] = RuntimeValueBox(value)
            storage.valueTypes[id] = valueType
            storage.restoredValues[id] = nil
            storage.dirtyComponents.insert(componentID)
        }
    }

    public func markDirty(_ componentID: ComponentID) {
        storage.withLock { storage in
            _ = storage.dirtyComponents.insert(componentID)
        }
    }

    public func contains(_ id: StateSlotID) -> Bool {
        storage.withLock { storage in
            storage.values[id] != nil || storage.restoredValues[id] != nil
        }
    }

    public func dirtyComponents() -> [ComponentID] {
        storage.withLock { storage in
            Array(storage.dirtyComponents)
        }
    }

    public func clearDirtyComponents(_ components: [ComponentID]) {
        storage.withLock { storage in
            for component in components {
                storage.dirtyComponents.remove(component)
            }
        }
    }

    public func snapshot(schemaHash: String) throws -> StateStoreSnapshot {
        let entries: [(id: StateSlotID, valueType: String, box: RuntimeValueBox)] = storage.withLock { storage in
            storage.values.compactMap { id, box in
                guard let valueType = storage.valueTypes[id] else {
                    return nil
                }
                return (id, valueType, box)
            }
        }

        var values: [String: StateSnapshotValue] = [:]
        for entry in entries {
            do {
                values[entry.id.rawValue] = try entry.box.snapshotValue(valueType: entry.valueType)
            } catch {
                throw StateSnapshotError.encodingFailed(
                    slotID: entry.id,
                    valueType: entry.valueType,
                    message: String(describing: error)
                )
            }
        }
        return StateStoreSnapshot(schemaHash: schemaHash, values: values)
    }

    public func restore(_ snapshot: StateStoreSnapshot) {
        storage.withLock { storage in
            storage.values.removeAll()
            storage.valueTypes.removeAll()
            storage.restoredValues = Dictionary(
                uniqueKeysWithValues: snapshot.values.map { key, value in
                    (StateSlotID(key), value)
                }
            )
            storage.dirtyComponents.removeAll()
        }
    }

    private static func decodeRestoredValue<Value: Sendable>(
        _ snapshot: StateSnapshotValue,
        as type: Value.Type
    ) -> Value? {
        guard snapshot.encoding == "json",
              let decodableType = Value.self as? any Decodable.Type
        else {
            return nil
        }

        do {
            let decoded = try JSONDecoder().decode(
                decodableType,
                from: Data(snapshot.encodedValue.utf8)
            )
            return decoded as? Value
        } catch {
            return nil
        }
    }

    private func install<Value: Sendable>(
        _ value: Value,
        for id: StateSlotID,
        valueType: String
    ) -> Value {
        storage.withLock { storage in
            if let existing = storage.values[id]?.value(as: Value.self) {
                return existing
            }
            storage.values[id] = RuntimeValueBox(value)
            storage.valueTypes[id] = valueType
            return value
        }
    }
}

public struct Binding<Value: Sendable> {
    private let getValue: () -> Value
    private let setValue: (Value) -> Void

    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void
    ) {
        self.getValue = get
        self.setValue = set
    }

    init<Root>(
        model: Root,
        keyPath: ReferenceWritableKeyPath<Root, Value>
    ) {
        self.getValue = {
            model[keyPath: keyPath]
        }
        self.setValue = { value in
            model[keyPath: keyPath] = value
        }
    }

    public var wrappedValue: Value {
        get {
            getValue()
        }
        nonmutating set {
            setValue(newValue)
        }
    }
}

@propertyWrapper
public struct State<Value: Sendable>: Sendable {
    private let initialValue: Value
    private let source: StateSourceLocation
    private let local: LocalStateStorage<Value>

    public init(
        wrappedValue: Value,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.initialValue = wrappedValue
        self.source = StateSourceLocation(
            fileID: String(describing: fileID),
            line: line,
            column: column
        )
        self.local = LocalStateStorage(wrappedValue)
    }

    public var wrappedValue: Value {
        get {
            guard let context = StateContext.current else {
                return local.value()
            }

            let slot = context.register(source: source, valueType: String(reflecting: Value.self))
            return context.store.value(for: slot.id, default: initialValue)
        }
        nonmutating set {
            guard let context = StateContext.current else {
                local.set(newValue)
                return
            }

            let slot = context.register(source: source, valueType: String(reflecting: Value.self))
            context.store.set(newValue, for: slot.id, componentID: context.componentID)
        }
    }

    public var projectedValue: Binding<Value> {
        // Capture the owning render context at projection time. `$state` is read
        // during the owner's body render, where `StateContext.current` is the
        // owner. The binding's get/set must target the owner's slot regardless of
        // which component later reads or writes through it, so we bind to the
        // captured context instead of re-resolving `StateContext.current` lazily.
        // Re-resolving would key the slot by whichever component is currently
        // rendering — passing `$state` to a child would then read and write a
        // different, phantom slot owned by the child, never updating the owner.
        let source = self.source
        let initialValue = self.initialValue
        let local = self.local
        let valueType = String(reflecting: Value.self)
        let ownerContext = StateContext.current
        return Binding(
            get: {
                guard let context = ownerContext else {
                    return local.value()
                }
                let slot = context.register(source: source, valueType: valueType)
                return context.store.value(for: slot.id, default: initialValue)
            },
            set: { newValue in
                guard let context = ownerContext else {
                    local.set(newValue)
                    return
                }
                let slot = context.register(source: source, valueType: valueType)
                context.store.set(newValue, for: slot.id, componentID: context.componentID)
            }
        )
    }
}

final class StateRenderContext: Sendable {
    let componentID: ComponentID
    let componentType: String
    let path: String
    let store: StateStore
    let isClientOwned: Bool

    private let storage = Mutex([StateSlotID: StateSlotRecord]())

    init(
        componentID: ComponentID,
        componentType: String,
        path: String,
        store: StateStore,
        isClientOwned: Bool
    ) {
        self.componentID = componentID
        self.componentType = componentType
        self.path = path
        self.store = store
        self.isClientOwned = isClientOwned
    }

    func register(source: StateSourceLocation, valueType: String) -> StateSlotRecord {
        let id = StateSlotID(componentID: componentID, source: source)
        return storage.withLock { storage in
            if let record = storage[id] {
                return record
            }

            let record = StateSlotRecord(
                id: id,
                componentID: componentID,
                valueType: valueType,
                source: source
            )
            storage[id] = record
            return record
        }
    }

    func stateSlots() -> [StateSlotRecord] {
        storage.withLock { storage in
            storage.values.sorted { left, right in
                left.id.rawValue < right.id.rawValue
            }
        }
    }
}

enum StateContext {
    @TaskLocal static var current: StateRenderContext?
}

private final class LocalStateStorage<Value: Sendable>: Sendable {
    private let storage: Mutex<Value>

    init(_ value: Value) {
        self.storage = Mutex(value)
    }

    func value() -> Value {
        storage.withLock { value in
            value
        }
    }

    func set(_ value: Value) {
        storage.withLock { storage in
            storage = value
        }
    }
}
