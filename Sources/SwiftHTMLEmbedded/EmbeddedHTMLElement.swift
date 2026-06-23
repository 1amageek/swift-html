public struct EmbeddedHTMLElement: Sendable, Equatable {
    public let tagName: String
    public let attributes: [EmbeddedHTMLAttribute]
    public let children: [EmbeddedHTMLNode]

    public init(
        _ tagName: String,
        attributes: [EmbeddedHTMLAttribute] = [],
        children: [EmbeddedHTMLNode] = []
    ) {
        self.tagName = tagName
        self.attributes = attributes
        self.children = children
    }

    public init(
        _ tagName: String,
        _ attributes: EmbeddedHTMLAttribute...,
        @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
    ) {
        self.init(tagName, attributes: attributes, children: children())
    }

    public func mount<Host: EmbeddedDOMHost>(
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
