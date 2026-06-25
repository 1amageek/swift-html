public protocol ComponentModifier: Sendable {
    associatedtype Body: HTML

    @HTMLBuilder
    func body(content: ModifierContent) -> Body
}
