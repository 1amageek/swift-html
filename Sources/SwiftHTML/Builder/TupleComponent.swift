public struct TupleComponent<each Content: HTML>: HTMLPrimitive {
    private let content: (repeat each Content)

    public init(_ content: repeat each Content) {
        self.content = (repeat each content)
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        var index = 0

        func appendChild<Child: HTML>(_ child: Child) {
            let segment = "tuple:\(index)"
            index += 1
            childIDs.append(builder.withPathSegment(segment) { scopedBuilder in
                scopedBuilder.append(child)
            })
        }

        repeat appendChild(each content)
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}
