public struct ClientHTMLDocument: Sendable, Equatable {
    public let children: [ClientHTMLNode]

    public init(@ClientHTMLBuilder children: () -> [ClientHTMLNode]) {
        self.children = children()
    }

    public func mount<Host: ClientDOMHost>(
        into host: Host,
        parent: Host.Node
    ) {
        for child in children {
            child.mount(into: host, parent: parent)
        }
    }
}
