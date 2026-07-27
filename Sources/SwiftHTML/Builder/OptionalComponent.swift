public struct OptionalComponent<Content: Component>: HTMLPrimitive {
    private let content: Content?

    public init(_ content: Content?) {
        self.content = content
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        guard let content else {
            return builder.addNode(kind: .fragment, children: [])
        }

        let childID = builder.withPathSegment("optional:some") { scopedBuilder in
            scopedBuilder.append(content)
        }
        return builder.addNode(kind: .fragment, children: [childID])
    }
}
