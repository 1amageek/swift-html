public protocol ClientDOMHost {
    associatedtype Node

    func createElement(_ tagName: String) -> Node
    func createText(_ text: String) -> Node
    func setAttribute(_ attribute: ClientHTMLAttribute, on node: Node)
    func appendChild(_ child: Node, to parent: Node)
}
