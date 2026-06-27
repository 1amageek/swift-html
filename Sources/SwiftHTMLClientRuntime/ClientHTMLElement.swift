public struct ClientHTMLElement: Sendable, Equatable {
    public let tagName: String
    public let attributes: [ClientHTMLAttribute]
    public let children: [ClientHTMLNode]

    public init(
        _ tagName: String,
        attributes: [ClientHTMLAttribute] = [],
        children: [ClientHTMLNode] = []
    ) {
        self.tagName = tagName
        self.attributes = attributes
        self.children = children
    }

    public init(
        _ tagName: String,
        _ attributes: ClientHTMLAttribute...,
        @ClientHTMLBuilder children: () -> [ClientHTMLNode]
    ) {
        self.init(tagName, attributes: attributes, children: children())
    }

    public func mount<Host: ClientDOMHost>(
        into host: Host,
        parent: Host.Node
    ) {
        let node = host.createElement(tagName)
        for attribute in attributes {
            host.setAttribute(attribute, on: node)
        }
        for child in children {
            child.mount(into: host, parent: node)
        }
        host.appendChild(node, to: parent)
    }
}
