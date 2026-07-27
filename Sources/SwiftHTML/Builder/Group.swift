public struct Group<Content: Component>: HTMLPrimitive {
    private let content: Content

    public init(@HTMLBuilder content: () -> Content) {
        self.content = content()
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.append(content)
    }
}
