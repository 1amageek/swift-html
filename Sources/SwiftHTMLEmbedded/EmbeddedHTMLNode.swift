public indirect enum EmbeddedHTMLNode: Sendable, Equatable {
    case element(EmbeddedHTMLElement)
    case text(String)

    public func mount<Host: EmbeddedDOMHost>(
        into host: Host,
        parent: Host.Node
    ) {
        switch self {
        case .element(let element):
            element.mount(into: host, parent: parent)
        case .text(let text):
            let node = host.createText(text)
            host.appendChild(node, to: parent)
        }
    }
}
