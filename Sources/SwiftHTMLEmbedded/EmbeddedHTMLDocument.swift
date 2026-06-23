public struct EmbeddedHTMLDocument: Sendable, Equatable {
    public let children: [EmbeddedHTMLNode]

    public init(@EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]) {
        self.children = children()
    }

    public func mount<Host: EmbeddedDOMHost>(
        into host: Host,
        parent: Host.Node
    ) {
        for child in children {
            child.mount(into: host, parent: parent)
        }
    }
}
