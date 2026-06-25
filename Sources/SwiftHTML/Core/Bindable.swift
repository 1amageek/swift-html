@propertyWrapper
public struct Bindable<Value: Sendable>: Sendable {
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    public var projectedValue: Bindable<Value> {
        self
    }
}
