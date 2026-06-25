public struct ForEach<
    Data: RandomAccessCollection & Sendable,
    ID: Hashable & Sendable,
    Content: HTML
>: HTMLPrimitive where Data.Element: Sendable {
    private let data: Data
    private let keyProvider: @Sendable (Data.Element) -> Key
    private let content: @Sendable (Data.Element) -> Content

    public init(
        _ data: Data,
        id: @escaping @Sendable (Data.Element) -> ID,
        @HTMLBuilder _ content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.keyProvider = { element in Key(id(element)) }
        self.content = content
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(data.count)
        var seenKeys = Set<Key>()
        var reportedDuplicateKeys = Set<Key>()
        var duplicateOccurrences: [Key: Int] = [:]

        for element in data {
            let key = keyProvider(element)
            var renderKey = key
            if !seenKeys.insert(key).inserted, reportedDuplicateKeys.insert(key).inserted {
                builder.report(RenderDiagnostic(
                    code: .duplicateKeyInForEach,
                    severity: .error,
                    message: "ForEach contains duplicate key '\(key.rawValue)'",
                    path: builder.renderPath(),
                    hint: "ForEach keys must be unique and stable so diffing, hydration, and @State identity can match the correct row."
                ))
            }

            if seenKeys.contains(key) {
                let occurrence = duplicateOccurrences[key, default: 0] + 1
                duplicateOccurrences[key] = occurrence
                if occurrence > 1 {
                    renderKey = key.disambiguated(occurrence: occurrence)
                }
            }

            childIDs.append(builder.append(content(element), key: renderKey))
        }

        return builder.addNode(kind: .fragment, children: childIDs)
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
