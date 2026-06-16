public enum ConditionalComponent<TrueContent: HTML, FalseContent: HTML>: HTMLPrimitive {
    case first(TrueContent)
    case second(FalseContent)

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        switch self {
        case .first(let content):
            let childID = builder.withPathSegment("conditional:first") { scopedBuilder in
                scopedBuilder.append(content)
            }
            return builder.addNode(kind: .fragment, children: [childID])
        case .second(let content):
            let childID = builder.withPathSegment("conditional:second") { scopedBuilder in
                scopedBuilder.append(content)
            }
            return builder.addNode(kind: .fragment, children: [childID])
        }
    }
}
