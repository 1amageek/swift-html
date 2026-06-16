public protocol ComponentModifier {
    associatedtype Body: HTML

    @HTMLBuilder
    func body(content: ModifierContent) -> Body
}
