public struct BrowserDOMCommandEncoder: Sendable {
    public init() {}

    public func encode(_ patches: [HTMLPatch]) -> BrowserDOMCommandBatch {
        BrowserDOMCommandBatch(commands: patches.map(command(for:)))
    }

    public func command(for patch: HTMLPatch) -> BrowserDOMCommand {
        switch patch.operation {
        case .replace(let node, let replacement):
            .replaceNode(node: node, replacement: replacement)
        case .replaceSubtree(let node, let html):
            .replaceSubtree(node: node, html: html)
        case .updateText(let node, let value):
            .updateText(node: node, value: value)
        case .updateComment(let node, let value):
            .updateComment(node: node, value: value)
        case .updateAttributes(let node, let attributes):
            .updateAttributes(node: node, attributes: attributes)
        case .setProperty(let node, let name, let value):
            .setProperty(node: node, name: name, value: value)
        case .insert(let parent, let index, let node):
            .insertNode(parent: parent, index: index, node: node)
        case .insertSubtree(let parent, let index, let html):
            .insertHTML(parent: parent, index: index, html: html)
        case .remove(let parent, let index, let node):
            .remove(parent: parent, index: index, node: node)
        case .move(let parent, let from, let to, let key):
            .move(parent: parent, from: from, to: to, key: key)
        case .moveKeyed(let parent, let key, let to):
            .moveKeyed(parent: parent, key: key, to: to)
        }
    }
}
