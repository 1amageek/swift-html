public struct ForEach<
    Data: RandomAccessCollection & Sendable,
    ID: Hashable & Sendable,
    Content: Component
>: HTMLPrimitive where Data.Element: Sendable {
    private let buildNodeClosure: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    public init(
        _ data: Data,
        id: @escaping @Sendable (Data.Element) -> ID,
        @HTMLBuilder _ content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.buildNodeClosure = { builder in
            var childIDs: [HTMLNodeID] = []
            childIDs.reserveCapacity(data.count)
            var seenIdentities = Set<String>()
            var reportedDuplicateIdentities = Set<String>()
            var duplicateOccurrences: [String: Int] = [:]

            for element in data {
                let key = Key(id(element))
                let identity = key.identity
                var renderKey = key
                if !seenIdentities.insert(identity).inserted,
                   reportedDuplicateIdentities.insert(identity).inserted {
                    builder.report(RenderDiagnostic(
                        code: .duplicateKeyInForEach,
                        severity: .error,
                        message: "ForEach contains duplicate key '\(key.rawValue)'",
                        path: builder.renderPath(),
                        hint: "ForEach keys must be unique and stable so diffing, hydration, and @State identity can match the correct row."
                    ))
                }

                if seenIdentities.contains(identity) {
                    let occurrence = duplicateOccurrences[identity, default: 0] + 1
                    duplicateOccurrences[identity] = occurrence
                    if occurrence > 1 {
                        renderKey = key.disambiguated(occurrence: occurrence)
                    }
                }

                childIDs.append(builder.append(content(element), key: renderKey))
            }

            return builder.addNode(kind: .fragment, children: childIDs)
        }
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        buildNodeClosure(&builder)
    }
}

public extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ data: Data,
        @HTMLBuilder _ content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.init(data, id: { element in element.id }, content)
    }
}
