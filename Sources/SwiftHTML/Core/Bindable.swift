@dynamicMemberLookup
@propertyWrapper
public struct Bindable<Value> {
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

    public subscript<Member: Sendable>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Member>) -> Binding<Member> {
        Binding(model: value, keyPath: keyPath)
    }
}
