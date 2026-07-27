public struct ModifierContent: HTMLPrimitive {
    @usableFromInline
    let build: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    @usableFromInline
    @_transparent
    init<Content: Component>(_ content: Content) {
        self.build = { builder in
            builder.append(content)
        }
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        build(&builder)
    }
}
