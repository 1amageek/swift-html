public enum BrowserDOMCommand: Sendable, Equatable {
    case replaceNode(node: HTMLNodeID, replacement: HTMLNodeID)
    case replaceSubtree(node: HTMLNodeID, html: String)
    case updateText(node: HTMLNodeID, value: String)
    case updateComment(node: HTMLNodeID, value: String)
    case updateAttributes(node: HTMLNodeID, attributes: [HTMLAttributeRecord])
    case setProperty(node: HTMLNodeID, name: String, value: String?)
    case insertNode(parent: HTMLNodeID, index: Int, node: HTMLNodeID)
    case insertHTML(parent: HTMLNodeID, index: Int, html: String)
    case remove(parent: HTMLNodeID, index: Int, node: HTMLNodeID)
    case move(parent: HTMLNodeID, from: Int, to: Int, key: Key)
    case moveKeyed(parent: HTMLNodeID, key: Key, to: Int)
}

#if !hasFeature(Embedded)
extension BrowserDOMCommand: Codable {}
#endif
