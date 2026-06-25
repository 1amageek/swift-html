public struct ModifierContent: HTMLPrimitive {
    private let build: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    init<Content: HTML>(_ content: Content) {
        self.build = { builder in
            builder.append(content)
        }
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        build(&builder)
    }
}
