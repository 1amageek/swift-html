public enum HTMLPatchOperation: Sendable, Equatable {
    case replace(node: HTMLNodeID, with: HTMLNodeID)
    case replaceSubtree(node: HTMLNodeID, html: String)
    case updateText(node: HTMLNodeID, value: String)
    case updateComment(node: HTMLNodeID, value: String)
    case updateAttributes(node: HTMLNodeID, attributes: [HTMLAttributeRecord])
    case setProperty(node: HTMLNodeID, name: String, value: String?)
    case insert(parent: HTMLNodeID, index: Int, node: HTMLNodeID)
    case insertSubtree(parent: HTMLNodeID, index: Int, html: String)
    case remove(parent: HTMLNodeID, index: Int, node: HTMLNodeID)
    case move(parent: HTMLNodeID, from: Int, to: Int, key: Key)
    case moveKeyed(parent: HTMLNodeID, key: Key, to: Int)
}

public struct HTMLPatch: Sendable, Equatable {
    public let operation: HTMLPatchOperation

    public init(_ operation: HTMLPatchOperation) {
        self.operation = operation
    }
}

public struct HTMLDiffer: Sendable {
    public init() {}

    func diff(
        from oldGraph: HTMLGraph,
        root oldRoot: HTMLNodeID,
        to newGraph: HTMLGraph,
        root newRoot: HTMLNodeID
    ) -> [HTMLPatch] {
        var patches: [HTMLPatch] = []
        diffNode(
            oldID: oldRoot,
            newID: newRoot,
            oldGraph: oldGraph,
            newGraph: newGraph,
            patches: &patches
        )
        return patches
    }

    public func diff(from oldArtifact: RenderArtifact, to newArtifact: RenderArtifact) -> [HTMLPatch] {
        diff(
            from: oldArtifact.graph,
            root: oldArtifact.rootID,
            to: newArtifact.graph,
            root: newArtifact.rootID
        )
    }

    private func diffNode(
        oldID: HTMLNodeID,
        newID: HTMLNodeID,
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph,
        patches: inout [HTMLPatch]
    ) {
        let oldNode = oldGraph.node(oldID)
        let newNode = newGraph.node(newID)

        if !sameKind(oldNode.kind, newNode.kind, oldGraph: oldGraph, newGraph: newGraph) {
            patches.append(HTMLPatch(.replaceSubtree(
                node: oldID,
                html: subtreeHTML(newID, in: newGraph)
            )))
            return
        }

        if case .serverSlot = oldNode.kind {
            diffClientOwnedDescendants(
                oldID: oldID,
                newID: newID,
                oldGraph: oldGraph,
                newGraph: newGraph,
                patches: &patches
            )
            return
        }

        if oldNode.fingerprint == newNode.fingerprint {
            return
        }

        switch (oldNode.kind, newNode.kind) {
        case (.text, .text):
            let oldValue = stringValue(for: oldID, in: oldGraph)
            let newValue = stringValue(for: newID, in: newGraph)
            if oldValue != newValue {
                patches.append(HTMLPatch(.updateText(node: oldID, value: newValue)))
            }
            return
        case (.rawHTML, .rawHTML):
            if stringValue(for: oldID, in: oldGraph) != stringValue(for: newID, in: newGraph) {
                patches.append(HTMLPatch(.replaceSubtree(
                    node: oldID,
                    html: subtreeHTML(newID, in: newGraph)
                )))
            }
            return
        case (.comment, .comment), (.placeholder, .placeholder):
            let newValue = stringValue(for: newID, in: newGraph)
            if stringValue(for: oldID, in: oldGraph) != newValue {
                patches.append(HTMLPatch(.updateComment(node: oldID, value: newValue)))
            }
            return
        default:
            break
        }

        let oldAttributes = oldGraph.attributes(of: oldID)
        let newAttributes = newGraph.attributes(of: newID)
        if oldAttributes != newAttributes {
            patches.append(HTMLPatch(.updateAttributes(node: oldID, attributes: newAttributes)))
            appendPropertyPatches(
                node: oldID,
                oldAttributes: oldAttributes,
                newAttributes: newAttributes,
                patches: &patches
            )
        }

        diffChildren(
            oldParent: oldID,
            newParent: newID,
            oldGraph: oldGraph,
            newGraph: newGraph,
            patches: &patches
        )
    }

    private func diffChildren(
        oldParent: HTMLNodeID,
        newParent: HTMLNodeID,
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph,
        patches: inout [HTMLPatch]
    ) {
        let oldChildren = oldGraph.children(of: oldParent)
        let newChildren = newGraph.children(of: newParent)
        let commonCount = Swift.min(oldChildren.count, newChildren.count)

        let oldKeyed = keyedChildren(oldChildren, in: oldGraph)
        let newKeyed = keyedChildren(newChildren, in: newGraph)

        if !oldKeyed.isEmpty || !newKeyed.isEmpty {
            diffKeyedChildren(
                oldParent: oldParent,
                oldChildren: oldChildren,
                newChildren: newChildren,
                oldKeyed: oldKeyed,
                newKeyed: newKeyed,
                oldGraph: oldGraph,
                newGraph: newGraph,
                patches: &patches
            )
            return
        }

        for index in 0..<commonCount {
            diffNode(
                oldID: oldChildren[index],
                newID: newChildren[index],
                oldGraph: oldGraph,
                newGraph: newGraph,
                patches: &patches
            )
        }

        if oldChildren.count > newChildren.count {
            for index in stride(from: oldChildren.count - 1, through: newChildren.count, by: -1) {
                patches.append(HTMLPatch(.remove(parent: oldParent, index: index, node: oldChildren[index])))
            }
        }

        if newChildren.count > oldChildren.count {
            for index in oldChildren.count..<newChildren.count {
                patches.append(HTMLPatch(.insertSubtree(
                    parent: oldParent,
                    index: index,
                    html: subtreeHTML(newChildren[index], in: newGraph)
                )))
            }
        }
    }

    private func diffClientOwnedDescendants(
        oldID: HTMLNodeID,
        newID: HTMLNodeID,
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph,
        patches: inout [HTMLPatch]
    ) {
        let oldChildren = oldGraph.children(of: oldID)
        let newChildren = newGraph.children(of: newID)
        let commonCount = Swift.min(oldChildren.count, newChildren.count)

        for index in 0..<commonCount {
            let oldChild = oldChildren[index]
            let newChild = newChildren[index]
            let oldNode = oldGraph.node(oldChild)
            let newNode = newGraph.node(newChild)

            switch (oldNode.kind, newNode.kind) {
            case (.component, .component):
                diffNode(
                    oldID: oldChild,
                    newID: newChild,
                    oldGraph: oldGraph,
                    newGraph: newGraph,
                    patches: &patches
                )
            case (.serverSlot, .serverSlot):
                if sameKind(oldNode.kind, newNode.kind, oldGraph: oldGraph, newGraph: newGraph) {
                    diffClientOwnedDescendants(
                        oldID: oldChild,
                        newID: newChild,
                        oldGraph: oldGraph,
                        newGraph: newGraph,
                        patches: &patches
                    )
                }
            default:
                if sameKind(oldNode.kind, newNode.kind, oldGraph: oldGraph, newGraph: newGraph) {
                    diffClientOwnedDescendants(
                        oldID: oldChild,
                        newID: newChild,
                        oldGraph: oldGraph,
                        newGraph: newGraph,
                        patches: &patches
                    )
                }
            }
        }
    }

    private func diffKeyedChildren(
        oldParent: HTMLNodeID,
        oldChildren: [HTMLNodeID],
        newChildren: [HTMLNodeID],
        oldKeyed: [Key: KeyedChild],
        newKeyed: [Key: KeyedChild],
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph,
        patches: inout [HTMLPatch]
    ) {
        let oldEntries = oldKeyed.sorted { left, right in
            left.value.index < right.value.index
        }
        let newEntries = newKeyed.sorted { left, right in
            left.value.index < right.value.index
        }

        for (key, oldEntry) in oldEntries.reversed() where newKeyed[key] == nil {
            patches.append(HTMLPatch(.remove(parent: oldParent, index: oldEntry.index, node: oldEntry.id)))
        }

        for (key, newEntry) in newEntries where oldKeyed[key] == nil {
            patches.append(HTMLPatch(.insertSubtree(
                parent: oldParent,
                index: newEntry.index,
                html: subtreeHTML(newEntry.id, in: newGraph)
            )))
        }

        for (key, oldEntry) in oldEntries {
            guard let newEntry = newKeyed[key] else {
                continue
            }
            diffNode(
                oldID: oldEntry.id,
                newID: newEntry.id,
                oldGraph: oldGraph,
                newGraph: newGraph,
                patches: &patches
            )

            if oldEntry.index != newEntry.index {
                patches.append(HTMLPatch(.moveKeyed(
                    parent: oldParent,
                    key: key,
                    to: newEntry.index
                )))
            }
        }

        diffUnkeyedChildren(
            oldParent: oldParent,
            oldChildren: oldChildren,
            newChildren: newChildren,
            oldGraph: oldGraph,
            newGraph: newGraph,
            patches: &patches
        )
    }

    private func diffUnkeyedChildren(
        oldParent: HTMLNodeID,
        oldChildren: [HTMLNodeID],
        newChildren: [HTMLNodeID],
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph,
        patches: inout [HTMLPatch]
    ) {
        let oldUnkeyed = unkeyedChildren(oldChildren, in: oldGraph)
        let newUnkeyed = unkeyedChildren(newChildren, in: newGraph)
        let commonCount = Swift.min(oldUnkeyed.count, newUnkeyed.count)

        for index in 0..<commonCount {
            diffNode(
                oldID: oldUnkeyed[index].id,
                newID: newUnkeyed[index].id,
                oldGraph: oldGraph,
                newGraph: newGraph,
                patches: &patches
            )
        }

        if oldUnkeyed.count > newUnkeyed.count {
            for index in stride(from: oldUnkeyed.count - 1, through: newUnkeyed.count, by: -1) {
                let child = oldUnkeyed[index]
                patches.append(HTMLPatch(.remove(parent: oldParent, index: child.index, node: child.id)))
            }
        }

        if newUnkeyed.count > oldUnkeyed.count {
            for index in oldUnkeyed.count..<newUnkeyed.count {
                let child = newUnkeyed[index]
                patches.append(HTMLPatch(.insertSubtree(
                    parent: oldParent,
                    index: child.index,
                    html: subtreeHTML(child.id, in: newGraph)
                )))
            }
        }
    }

    private func keyedChildren(_ children: [HTMLNodeID], in graph: HTMLGraph) -> [Key: KeyedChild] {
        var result: [Key: KeyedChild] = [:]
        for (index, id) in children.enumerated() {
            guard let key = graph.node(id).key else {
                continue
            }
            result[key] = KeyedChild(index: index, id: id)
        }
        return result
    }

    private func unkeyedChildren(_ children: [HTMLNodeID], in graph: HTMLGraph) -> [KeyedChild] {
        var result: [KeyedChild] = []
        for (index, id) in children.enumerated() {
            guard graph.node(id).key == nil else {
                continue
            }
            result.append(KeyedChild(index: index, id: id))
        }
        return result
    }

    private func sameKind(
        _ oldKind: HTMLNodeKind,
        _ newKind: HTMLNodeKind,
        oldGraph: HTMLGraph,
        newGraph: HTMLGraph
    ) -> Bool {
        switch (oldKind, newKind) {
        case (.document, .document), (.doctype, .doctype), (.fragment, .fragment):
            true
        case (.element(let oldName), .element(let newName)):
            oldGraph.string(oldName) == newGraph.string(newName)
        case (.text, .text), (.rawHTML, .rawHTML), (.placeholder, .placeholder), (.comment, .comment):
            true
        case (.component(let oldID), .component(let newID)):
            oldID == newID
        case (.serverSlot(let oldID), .serverSlot(let newID)):
            oldID == newID
        default:
            false
        }
    }

    private func stringValue(for id: HTMLNodeID, in graph: HTMLGraph) -> String {
        switch graph.node(id).kind {
        case .text(let stringID), .rawHTML(let stringID), .placeholder(let stringID), .comment(let stringID):
            graph.string(stringID)
        default:
            ""
        }
    }

    private func appendPropertyPatches(
        node: HTMLNodeID,
        oldAttributes: [HTMLAttributeRecord],
        newAttributes: [HTMLAttributeRecord],
        patches: inout [HTMLPatch]
    ) {
        let oldProperties = propertyBindingsByName(oldAttributes)
        let newProperties = propertyBindingsByName(newAttributes)
        let names = Set(oldProperties.keys).union(newProperties.keys).sorted()

        for name in names where oldProperties[name]?.value != newProperties[name]?.value {
            patches.append(HTMLPatch(.setProperty(
                node: node,
                name: name,
                value: newProperties[name]?.value
            )))
        }
    }

    private func propertyBindingsByName(_ attributes: [HTMLAttributeRecord]) -> [String: HTMLAttributeRecord] {
        var bindings: [String: HTMLAttributeRecord] = [:]
        for attribute in attributes where attribute.kind == .propertyBinding {
            bindings[attribute.name] = attribute
        }
        return bindings
    }

    private func subtreeHTML(_ id: HTMLNodeID, in graph: HTMLGraph) -> String {
        HTMLRenderer().renderSubtree(id, graph: graph)
    }
}

private struct KeyedChild: Equatable {
    let index: Int
    let id: HTMLNodeID
}
