public struct HTMLDOMNode: Sendable, Equatable {
    public var id: HTMLNodeID
    public var kind: HTMLDOMNodeKind
    public var attributes: [HTMLAttributeRecord]
    public var children: [HTMLDOMChild]
    public var flags: HTMLNodeFlags
    public var key: Key?

    public init(
        id: HTMLNodeID,
        kind: HTMLDOMNodeKind,
        attributes: [HTMLAttributeRecord] = [],
        children: [HTMLDOMChild] = [],
        flags: HTMLNodeFlags = [],
        key: Key? = nil
    ) {
        self.id = id
        self.kind = kind
        self.attributes = attributes
        self.children = children
        self.flags = flags
        self.key = key
    }
}
