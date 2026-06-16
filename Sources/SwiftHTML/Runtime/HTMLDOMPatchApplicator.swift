public struct HTMLDOMPatchApplicator: Sendable {
    public init() {}

    public func apply(
        _ patches: [HTMLPatch],
        to snapshot: HTMLDOMSnapshot
    ) throws -> HTMLDOMSnapshot {
        var result = snapshot
        for patch in patches {
            try apply(patch, to: &result)
        }
        return result
    }

    public func apply(
        _ patch: HTMLPatch,
        to snapshot: inout HTMLDOMSnapshot
    ) throws {
        switch patch.operation {
        case .replace(let node, let replacement):
            try replace(node, with: replacement, in: &snapshot)
        case .replaceSubtree(let node, let html):
            try replaceSubtree(node, html: html, in: &snapshot)
        case .updateText(let node, let value):
            try updateText(node, value: value, in: &snapshot)
        case .updateComment(let node, let value):
            try updateComment(node, value: value, in: &snapshot)
        case .updateAttributes(let node, let attributes):
            try updateAttributes(node, attributes: attributes, in: &snapshot)
        case .setProperty(let node, let name, let value):
            try setProperty(node, name: name, value: value, in: &snapshot)
        case .insert(let parent, let index, let node):
            try insert(.node(node), into: parent, at: index, in: &snapshot)
        case .insertSubtree(let parent, let index, let html):
            try insert(.html(html), into: parent, at: index, in: &snapshot)
        case .remove(let parent, let index, let node):
            try remove(node, from: parent, at: index, in: &snapshot)
        case .move(let parent, let from, let to, _):
            try moveChild(in: parent, from: from, to: to, snapshot: &snapshot)
        case .moveKeyed(let parent, let key, let to):
            try moveKeyedChild(in: parent, key: key, to: to, snapshot: &snapshot)
        }
    }

    private func replace(
        _ nodeID: HTMLNodeID,
        with replacementID: HTMLNodeID,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard snapshot.nodes[nodeID] != nil else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }
        guard let replacement = snapshot.nodes[replacementID] else {
            throw HTMLDOMPatchError.missingNode(replacementID)
        }
        snapshot.nodes[nodeID] = HTMLDOMNode(
            id: nodeID,
            kind: replacement.kind,
            attributes: replacement.attributes,
            children: replacement.children,
            flags: replacement.flags,
            key: replacement.key
        )
    }

    private func replaceSubtree(
        _ nodeID: HTMLNodeID,
        html: String,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard let node = snapshot.nodes[nodeID] else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }
        snapshot.nodes[nodeID] = HTMLDOMNode(
            id: nodeID,
            kind: .opaqueHTML(html),
            flags: node.flags,
            key: node.key
        )
    }

    private func updateText(
        _ nodeID: HTMLNodeID,
        value: String,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var node = snapshot.nodes[nodeID] else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }
        node.kind = .text(value)
        snapshot.nodes[nodeID] = node
    }

    private func updateComment(
        _ nodeID: HTMLNodeID,
        value: String,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var node = snapshot.nodes[nodeID] else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }
        switch node.kind {
        case .placeholder:
            node.kind = .placeholder(value)
        default:
            node.kind = .comment(value)
        }
        snapshot.nodes[nodeID] = node
    }

    private func updateAttributes(
        _ nodeID: HTMLNodeID,
        attributes: [HTMLAttributeRecord],
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var node = snapshot.nodes[nodeID] else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }
        node.attributes = attributes
        snapshot.nodes[nodeID] = node
    }

    private func setProperty(
        _ nodeID: HTMLNodeID,
        name: String,
        value: String?,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var node = snapshot.nodes[nodeID] else {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }

        if let index = node.attributes.firstIndex(where: { $0.name == name }) {
            if let value {
                node.attributes[index] = HTMLAttributeRecord(
                    name: name,
                    value: value,
                    kind: .propertyBinding,
                    handlerID: node.attributes[index].handlerID,
                    eventName: node.attributes[index].eventName
                )
            } else {
                node.attributes.remove(at: index)
            }
        } else if let value {
            node.attributes.append(HTMLAttributeRecord(
                name: name,
                value: value,
                kind: .propertyBinding
            ))
        }

        snapshot.nodes[nodeID] = node
    }

    private func insert(
        _ child: HTMLDOMChild,
        into parentID: HTMLNodeID,
        at index: Int,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var parent = snapshot.nodes[parentID] else {
            throw HTMLDOMPatchError.missingNode(parentID)
        }
        guard index >= 0 && index <= parent.children.count else {
            throw HTMLDOMPatchError.childIndexOutOfBounds(parent: parentID, index: index)
        }
        if case .node(let nodeID) = child, snapshot.nodes[nodeID] == nil {
            throw HTMLDOMPatchError.missingNode(nodeID)
        }

        parent.children.insert(child, at: index)
        snapshot.nodes[parentID] = parent
    }

    private func remove(
        _ nodeID: HTMLNodeID,
        from parentID: HTMLNodeID,
        at index: Int,
        in snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var parent = snapshot.nodes[parentID] else {
            throw HTMLDOMPatchError.missingNode(parentID)
        }
        guard index >= 0 && index < parent.children.count else {
            throw HTMLDOMPatchError.childIndexOutOfBounds(parent: parentID, index: index)
        }

        let child = parent.children[index]
        if case .node(let actualID) = child, actualID != nodeID {
            throw HTMLDOMPatchError.childNodeMismatch(
                parent: parentID,
                index: index,
                expected: nodeID,
                actual: actualID
            )
        }

        parent.children.remove(at: index)
        snapshot.nodes[parentID] = parent
    }

    private func moveChild(
        in parentID: HTMLNodeID,
        from sourceIndex: Int,
        to destinationIndex: Int,
        snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var parent = snapshot.nodes[parentID] else {
            throw HTMLDOMPatchError.missingNode(parentID)
        }
        guard sourceIndex >= 0 && sourceIndex < parent.children.count else {
            throw HTMLDOMPatchError.childIndexOutOfBounds(parent: parentID, index: sourceIndex)
        }

        let child = parent.children.remove(at: sourceIndex)
        guard destinationIndex >= 0 && destinationIndex <= parent.children.count else {
            throw HTMLDOMPatchError.childIndexOutOfBounds(parent: parentID, index: destinationIndex)
        }
        parent.children.insert(child, at: destinationIndex)
        snapshot.nodes[parentID] = parent
    }

    private func moveKeyedChild(
        in parentID: HTMLNodeID,
        key: Key,
        to destinationIndex: Int,
        snapshot: inout HTMLDOMSnapshot
    ) throws {
        guard var parent = snapshot.nodes[parentID] else {
            throw HTMLDOMPatchError.missingNode(parentID)
        }
        guard let sourceIndex = parent.children.firstIndex(where: { child in
            guard case .node(let id) = child else {
                return false
            }
            return snapshot.nodes[id]?.key == key
        }) else {
            throw HTMLDOMPatchError.keyedChildNotFound(parent: parentID, key: key)
        }

        let child = parent.children.remove(at: sourceIndex)
        guard destinationIndex >= 0 && destinationIndex <= parent.children.count else {
            throw HTMLDOMPatchError.childIndexOutOfBounds(parent: parentID, index: destinationIndex)
        }
        parent.children.insert(child, at: destinationIndex)
        snapshot.nodes[parentID] = parent
    }
}
