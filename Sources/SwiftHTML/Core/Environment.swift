import Foundation

public protocol EnvironmentKey: Sendable {
    associatedtype Value: Sendable

    static var defaultValue: Value { get }
    static var environmentKey: String { get }
    static var visibility: EnvironmentVisibility { get }
    static func clientSnapshotValue(_ value: Value) throws -> ClientEnvironmentSnapshotValue?
}

public extension EnvironmentKey {
    static var environmentKey: String {
        String(reflecting: Self.self)
    }

    static var visibility: EnvironmentVisibility {
        .serverOnly
    }

    static func clientSnapshotValue(_ value: Value) throws -> ClientEnvironmentSnapshotValue? {
        nil
    }
}

public struct EnvironmentValues: Sendable {
    private var storage: [ObjectIdentifier: RuntimeValueBox]

    public init() {
        self.storage = [:]
    }

    public subscript<Key: EnvironmentKey>(_ key: Key.Type) -> Key.Value {
        get {
            let value = storage[ObjectIdentifier(key)]?.value(as: Key.Value.self) ?? Key.defaultValue
            let read = EnvironmentReadRecord(
                key: Key.environmentKey,
                valueType: String(reflecting: Key.Value.self),
                visibility: Key.visibility
            )
            let snapshot: ClientEnvironmentSnapshotValue?
            let snapshotError: ClientEnvironmentSnapshotError?
            do {
                snapshot = try Key.clientSnapshotValue(value)
                snapshotError = nil
            } catch let error as ClientEnvironmentSnapshotError {
                snapshot = nil
                snapshotError = error
            } catch {
                snapshot = nil
                snapshotError = ClientEnvironmentSnapshotError.encodingFailed(
                    key: Key.environmentKey,
                    valueType: String(reflecting: Key.Value.self),
                    message: String(describing: error)
                )
            }
            EnvironmentReadContext.current?.record(
                read,
                snapshot: snapshot,
                snapshotError: snapshotError
            )
            return value
        }
        set {
            storage[ObjectIdentifier(key)] = RuntimeValueBox(newValue)
        }
    }

    public subscript<Value: Sendable>(_ type: Value.Type) -> Value? {
        get {
            let value = storage[ObjectIdentifier(type)]?.value(as: Value.self)
            EnvironmentReadContext.current?.record(
                EnvironmentReadRecord(
                    key: String(reflecting: type),
                    valueType: String(reflecting: type),
                    visibility: .runtimeOnly
                ),
                snapshot: nil
            )
            return value
        }
        set {
            if let newValue {
                storage[ObjectIdentifier(type)] = RuntimeValueBox(newValue)
            } else {
                storage.removeValue(forKey: ObjectIdentifier(type))
            }
        }
    }

    public func contains<Value: Sendable>(_ type: Value.Type) -> Bool {
        storage[ObjectIdentifier(type)]?.value(as: Value.self) != nil
    }

    public static func withValue<Result: Sendable>(
        _ value: EnvironmentValues,
        operation: @Sendable () async throws -> Result
    ) async rethrows -> Result {
        try await EnvironmentContext.$current.withValue(value, operation: operation)
    }
}

enum EnvironmentContext {
    @TaskLocal static var current = EnvironmentValues()
}

@propertyWrapper
public struct Environment<Value: Sendable> {
    private let read: (EnvironmentValues) -> Value

    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.read = { values in
            values[keyPath: keyPath]
        }
    }

    public init<Wrapped>(_ type: Wrapped.Type) where Value == Wrapped? {
        self.read = { values in
            values[type]
        }
    }

    public var wrappedValue: Value {
        read(EnvironmentContext.current)
    }
}

public extension HTML {
    func environment<Value: Sendable>(
        _ keyPath: WritableKeyPath<EnvironmentValues, Value>,
        _ value: Value
    ) -> some HTML {
        EnvironmentModifier(keyPath, value) {
            self
        }
    }

    func environment<Value: Sendable>(_ value: Value) -> some HTML {
        EnvironmentModifier(value) {
            self
        }
    }

    func environment<Key: EnvironmentKey>(
        _ key: Key.Type,
        _ value: Key.Value
    ) -> some HTML {
        EnvironmentModifier(key, value: value) {
            self
        }
    }
}

public enum ColorScheme: String, Codable, Sendable {
    case light
    case dark
}

public enum LayoutDirection: String, Codable, Sendable {
    case leftToRight
    case rightToLeft
}

// These keys are `internal` (not `private`) so that `String(reflecting:)`
// yields a stable `SwiftHTML.<Name>` identity that matches across the
// separately compiled server and WASM binaries. A `private` key reflects to
// `SwiftHTML.(unknown context at $<address>).<Name>`, whose discriminator
// differs per binary, so a snapshot produced by the server can never be decoded
// by the client. They are registered for hydration in `ClientEnvironmentRegistry.standard`.
struct LocaleEnvironmentKey: ClientEnvironmentKey {
    static var defaultValue: Locale { .current }
}

struct TimeZoneEnvironmentKey: ClientEnvironmentKey {
    static var defaultValue: TimeZone { .current }
}

struct CalendarEnvironmentKey: ClientEnvironmentKey {
    static var defaultValue: Calendar { .current }
}

struct ColorSchemeEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = ColorScheme.light
}

struct LayoutDirectionEnvironmentKey: ClientEnvironmentKey {
    static let defaultValue = LayoutDirection.leftToRight
}

public extension EnvironmentValues {
    var locale: Locale {
        get { self[LocaleEnvironmentKey.self] }
        set { self[LocaleEnvironmentKey.self] = newValue }
    }

    var timeZone: TimeZone {
        get { self[TimeZoneEnvironmentKey.self] }
        set { self[TimeZoneEnvironmentKey.self] = newValue }
    }

    var calendar: Calendar {
        get { self[CalendarEnvironmentKey.self] }
        set { self[CalendarEnvironmentKey.self] = newValue }
    }

    var colorScheme: ColorScheme {
        get { self[ColorSchemeEnvironmentKey.self] }
        set { self[ColorSchemeEnvironmentKey.self] = newValue }
    }

    var layoutDirection: LayoutDirection {
        get { self[LayoutDirectionEnvironmentKey.self] }
        set { self[LayoutDirectionEnvironmentKey.self] = newValue }
    }
}
