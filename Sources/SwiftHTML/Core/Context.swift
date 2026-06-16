public protocol ContextKey: EnvironmentKey {}

@propertyWrapper
public struct Context<Key: ContextKey>: Sendable {
    public init(_ key: Key.Type) {}

    public var wrappedValue: Key.Value {
        EnvironmentContext.current[Key.self]
    }
}
