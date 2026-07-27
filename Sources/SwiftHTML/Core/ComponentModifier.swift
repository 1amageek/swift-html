public protocol ComponentModifier: Sendable {
    associatedtype Content: Component

    @ComponentBuilder
    func content(_ content: ModifierContent) -> Content
}
