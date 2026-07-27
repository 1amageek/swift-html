import Synchronization

#if canImport(Foundation)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

public struct StateSourceLocation: Sendable, Hashable {
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

public struct StateSlotID: Sendable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(componentID: ComponentID, source: StateSourceLocation) {
        self.rawValue = "\(componentID.rawValue):state:\(source.rawValue)"
    }
}

public struct StateSlotRecord: Sendable, Equatable {
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
    private struct ValueEntry: Sendable {
        var id: StateSlotID
        var value: RuntimeValueBox
        var valueType: String
    }

    private struct RestoredValueEntry: Sendable {
        var id: StateSlotID
        var value: StateSnapshotValue
    }

    private struct Storage: Sendable {
        var values: [ValueEntry] = []
        var restoredValues: [RestoredValueEntry] = []
        var dirtyComponents: [ComponentID] = []
    }

    private let storage = SwiftHTMLMutex(Storage())

    public init() {}

    public func value<Value: Sendable>(
        for id: StateSlotID,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        let valueType = RuntimeTypeName.reflecting(Value.self)
        let lookup: (existing: Value?, restored: StateSnapshotValue?) = storage.withLock { storage in
            for entry in storage.values {
                if entry.id == id,
                   let existing = entry.value.value(as: Value.self) {
                    return (existing, nil)
                }
            }

            let restored = storage.restoredValues.first { entry in
                entry.id == id
            }?.value
            if let restored {
                return (nil, restored)
            }

            return (nil, nil)
        }

        if let existing = lookup.existing {
            return existing
        }

        if let restored = lookup.restored {
            if restored.valueType == valueType,
               let restoredValue = Self.decodeRestoredValue(restored, as: Value.self, slot: id) {
                return installRestored(
                    restoredValue,
                    snapshot: restored,
                    for: id,
                    valueType: valueType
                )
            }
            if restored.valueType != valueType {
                Self.reportRestoreFailure(
                    slot: id,
                    valueType: valueType,
                    error: StateRestoreFailure.valueTypeMismatch(
                        expected: valueType,
                        actual: restored.valueType
                    )
                )
            }
            discardRestored(restored, for: id)
        }

        return install(defaultValue(), for: id, valueType: valueType)
    }

    public func set<Value: Sendable>(
        _ value: Value,
        for id: StateSlotID,
        componentID: ComponentID
    ) {
        let valueType = RuntimeTypeName.reflecting(Value.self)
        storage.withLock { storage in
            var didUpdateValue = false
            for index in storage.values.indices {
                if storage.values[index].id == id {
                    storage.values[index].value = RuntimeValueBox(value)
                    storage.values[index].valueType = valueType
                    didUpdateValue = true
                    break
                }
            }
            if !didUpdateValue {
                storage.values.append(
                    ValueEntry(id: id, value: RuntimeValueBox(value), valueType: valueType)
                )
            }
            storage.restoredValues.removeAll { $0.id == id }
            if !storage.dirtyComponents.contains(componentID) {
                storage.dirtyComponents.append(componentID)
            }
        }
    }

    public func markDirty(_ componentID: ComponentID) {
        storage.withLock { storage in
            if !storage.dirtyComponents.contains(componentID) {
                storage.dirtyComponents.append(componentID)
            }
        }
    }

    public func contains(_ id: StateSlotID) -> Bool {
        storage.withLock { storage in
            storage.values.contains { $0.id == id }
                || storage.restoredValues.contains { $0.id == id }
        }
    }

    public func dirtyComponents() -> [ComponentID] {
        storage.withLock { storage in
            storage.dirtyComponents
        }
    }

    public func clearDirtyComponents(_ components: [ComponentID]) {
        storage.withLock { storage in
            storage.dirtyComponents.removeAll { components.contains($0) }
        }
    }

    public func snapshot(schemaHash: String) throws -> StateStoreSnapshot {
        let entries: [(id: StateSlotID, valueType: String, box: RuntimeValueBox)] = storage.withLock { storage in
            storage.values.map { entry in
                (entry.id, entry.valueType, entry.value)
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
                    message: RuntimeTypeName.errorDescription(error)
                )
            }
        }
        return StateStoreSnapshot(schemaHash: schemaHash, values: values)
    }

    public func restore(_ snapshot: StateStoreSnapshot) {
        storage.withLock { storage in
            storage.values.removeAll()
            storage.restoredValues = snapshot.values.map { key, value in
                RestoredValueEntry(id: StateSlotID(key), value: value)
            }
            storage.dirtyComponents.removeAll()
        }
    }

    private static func decodeRestoredValue<Value: Sendable>(
        _ snapshot: StateSnapshotValue,
        as type: Value.Type,
        slot id: StateSlotID
    ) -> Value? {
        #if canImport(Foundation)
        guard snapshot.encoding == "json" else {
            reportRestoreFailure(
                slot: id,
                valueType: RuntimeTypeName.reflecting(Value.self),
                error: StateRestoreFailure.unsupportedEncoding(snapshot.encoding)
            )
            return nil
        }
        guard let decodableType = Value.self as? any Decodable.Type else {
            reportRestoreFailure(
                slot: id,
                valueType: RuntimeTypeName.reflecting(Value.self),
                error: StateRestoreFailure.valueIsNotDecodable
            )
            return nil
        }

        do {
            #if os(WASI)
            let decoded = try SwiftHTMLJSONDecoder.decode(
                decodableType,
                from: Data(snapshot.encodedValue.utf8)
            )
            #else
            let decoded = try JSONDecoder().decode(
                decodableType,
                from: Data(snapshot.encodedValue.utf8)
            )
            #endif
            guard let value = decoded as? Value else {
                reportRestoreFailure(
                    slot: id,
                    valueType: RuntimeTypeName.reflecting(Value.self),
                    error: StateRestoreFailure.decodedTypeMismatch
                )
                return nil
            }
            return value
        } catch {
            // A JSON snapshot of a Decodable type whose slot matched but failed to
            // decode is a genuine restore failure. Surface it instead of silently
            // resetting the control to its default — otherwise hydration loses the
            // user's value with no signal.
            reportRestoreFailure(slot: id, valueType: RuntimeTypeName.reflecting(Value.self), error: error)
            return nil
        }
        #else
        return nil
        #endif
    }

    private static func reportRestoreFailure(slot id: StateSlotID, valueType: String, error: Error) {
        let message = "[SwiftHTML] @State restore failed for slot \"\(id.rawValue)\" "
            + "(\(valueType)): \(RuntimeTypeName.errorDescription(error)). "
            + "The value was reset to its default."
        #if canImport(Foundation) && !canImport(FoundationEssentials)
        FileHandle.standardError.write(Data((message + "\n").utf8))
        #else
        // FoundationEssentials hosts have no FileHandle, and Embedded has no
        // Foundation at all; both route standard output to the console.
        print(message)
        #endif
    }

    private func install<Value: Sendable>(
        _ value: Value,
        for id: StateSlotID,
        valueType: String
    ) -> Value {
        storage.withLock { storage in
            for index in storage.values.indices {
                if storage.values[index].id == id {
                    if let existing = storage.values[index].value.value(as: Value.self) {
                        return existing
                    }
                    storage.values[index] = ValueEntry(
                        id: id,
                        value: RuntimeValueBox(value),
                        valueType: valueType
                    )
                    return value
                }
            }
            storage.values.append(
                ValueEntry(id: id, value: RuntimeValueBox(value), valueType: valueType)
            )
            return value
        }
    }

    private func installRestored<Value: Sendable>(
        _ value: Value,
        snapshot: StateSnapshotValue,
        for id: StateSlotID,
        valueType: String
    ) -> Value {
        storage.withLock { storage in
            for index in storage.values.indices {
                if storage.values[index].id == id {
                    if let existing = storage.values[index].value.value(as: Value.self) {
                        return existing
                    }
                    storage.values[index] = ValueEntry(
                        id: id,
                        value: RuntimeValueBox(value),
                        valueType: valueType
                    )
                    storage.restoredValues.removeAll { entry in
                        entry.id == id && entry.value == snapshot
                    }
                    return value
                }
            }
            storage.values.append(
                ValueEntry(id: id, value: RuntimeValueBox(value), valueType: valueType)
            )
            storage.restoredValues.removeAll { entry in
                entry.id == id && entry.value == snapshot
            }
            return value
        }
    }

    private func discardRestored(_ snapshot: StateSnapshotValue, for id: StateSlotID) {
        storage.withLock { storage in
            storage.restoredValues.removeAll { entry in
                entry.id == id && entry.value == snapshot
            }
        }
    }
}

private enum StateRestoreFailure: Error, CustomStringConvertible {
    case unsupportedEncoding(String)
    case valueIsNotDecodable
    case valueTypeMismatch(expected: String, actual: String)
    case decodedTypeMismatch

    var description: String {
        switch self {
        case .unsupportedEncoding(let encoding):
            "Unsupported state snapshot encoding: \(encoding)"
        case .valueIsNotDecodable:
            "The state value type does not conform to Decodable"
        case .valueTypeMismatch(let expected, let actual):
            "State snapshot type mismatch: expected \(expected), found \(actual)"
        case .decodedTypeMismatch:
            "The decoded state value did not match the requested type"
        }
    }
}

public struct Binding<Value: Sendable>: Sendable {
    private let getValue: @Sendable () -> Value
    private let setValue: @Sendable (Value) -> Void

    public init(
        get: @escaping @Sendable () -> Value,
        set: @escaping @Sendable (Value) -> Void
    ) {
        self.getValue = get
        self.setValue = set
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
            fileID: RuntimeTypeName.sourceFileID(fileID),
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

            let slot = context.register(source: source, valueType: RuntimeTypeName.reflecting(Value.self))
            return context.store.value(for: slot.id, default: initialValue)
        }
        nonmutating set {
            guard let context = StateContext.current else {
                local.set(newValue)
                return
            }

            let slot = context.register(source: source, valueType: RuntimeTypeName.reflecting(Value.self))
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
        let valueType = RuntimeTypeName.reflecting(Value.self)
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
    private struct Storage: Sendable {
        var slots: [StateSlotRecord] = []
    }

    let componentID: ComponentID
    let componentType: String
    let path: String
    let store: StateStore
    let isClientOwned: Bool

    private let storage = SwiftHTMLMutex(Storage())

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
            for record in storage.slots {
                if record.id == id {
                    return record
                }
            }

            let record = StateSlotRecord(
                id: id,
                componentID: componentID,
                valueType: valueType,
                source: source
            )
            storage.slots.append(record)
            return record
        }
    }

    func stateSlots() -> [StateSlotRecord] {
        storage.withLock { storage in
            storage.slots.sorted { left, right in
                left.id.rawValue < right.id.rawValue
            }
        }
    }
}

enum StateContext {
    @TaskLocal static var current: StateRenderContext?

    static func withValue<Result>(
        _ value: StateRenderContext?,
        operation: () throws -> Result
    ) rethrows -> Result {
        try $current.withValue(value, operation: operation)
    }
}

private final class LocalStateStorage<Value: Sendable>: Sendable {
    private let storage: SwiftHTMLMutex<Value>

    init(_ value: Value) {
        self.storage = SwiftHTMLMutex(value)
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

#if !hasFeature(Embedded)
extension StateSourceLocation: Codable {}
extension StateSlotID: Codable {}
extension StateSlotRecord: Codable {}
#endif
