public indirect enum ClientHTMLNode: Sendable, Equatable {
    case element(ClientHTMLElement)
    case text(String)

    public func mount<Host: ClientDOMHost>(
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
