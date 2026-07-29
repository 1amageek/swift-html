public struct ModifiedContent: HTMLPrimitive {
    @usableFromInline
    let buildNodeClosure: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    @_transparent
    public init<Content: Component, Modifier: ComponentModifier>(
        content: Content,
        modifier: Modifier
    ) {
        self.init(
            content: ComponentContent(content),
            modify: { modifierContent in
                ComponentContent(modifier.content(modifierContent))
            }
        )
    }

    @usableFromInline
    init(
        content: ComponentContent,
        modify: @escaping @Sendable (ModifierContent) -> ComponentContent
    ) {
        self.buildNodeClosure = { builder in
            let modifiedContent = EnvironmentContext.withValue(builder.environment) {
                modify(ModifierContent(content))
            }
            return modifiedContent.buildNodeClosure(&builder)
        }
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        buildNodeClosure(&builder)
    }
}

public extension Component {
    @_transparent
    func modifier<Modifier: ComponentModifier>(
        _ modifier: Modifier
    ) -> ModifiedContent {
        ModifiedContent(content: self, modifier: modifier)
    }
}
