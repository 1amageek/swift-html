public struct ArrayComponent<Content: HTML>: HTMLPrimitive {
    private let content: [Content]

    public init(_ content: [Content]) {
        self.content = content
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(content.count)
        for (index, child) in content.enumerated() {
            childIDs.append(builder.withPathSegment("array:\(index)") { scopedBuilder in
                scopedBuilder.append(child)
            })
        }
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}
