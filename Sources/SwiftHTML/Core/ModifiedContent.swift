public struct ModifiedContent<Content: HTML, Modifier: ComponentModifier>: HTMLPrimitive {
    public let content: Content
    public let modifier: Modifier

    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        let body = modifier.body(content: ModifierContent(content))
        return builder.append(body)
    }
}

public extension HTML {
    func modifier<Modifier: ComponentModifier>(
        _ modifier: Modifier
    ) -> ModifiedContent<Self, Modifier> {
        ModifiedContent(content: self, modifier: modifier)
    }
}
