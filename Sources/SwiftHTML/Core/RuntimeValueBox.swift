struct RuntimeValueBox: Sendable {
    private let storedValue: any Sendable

    init<Value: Sendable>(_ value: Value) {
        self.storedValue = value
    }

    func value<Value: Sendable>(as type: Value.Type = Value.self) -> Value? {
        storedValue as? Value
    }
}
