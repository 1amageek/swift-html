public struct ModifiedContent: HTMLPrimitive {
    @usableFromInline
    let buildNodeClosure: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    public init<Content: Component, Modifier: ComponentModifier>(
        content: Content,
        modifier: Modifier
    ) {
        self.buildNodeClosure = { builder in
            let modifiedContent = EnvironmentContext.withValue(builder.environment) {
                modifier.content(ModifierContent(content))
            }
            return ComponentContent(modifiedContent).buildNodeClosure(&builder)
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
