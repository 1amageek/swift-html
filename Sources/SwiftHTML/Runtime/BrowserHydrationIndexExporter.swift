public struct BrowserHydrationIndexExporter: Sendable {
    public init() {}

    public func export(_ artifact: RenderArtifact) -> BrowserHydrationIndex {
        let parentIDs = parentIDs(in: artifact.graph)
        let handlerComponents = handlerComponents(in: artifact.clientHandlers)
        var allHandlers: [BrowserHydrationEventBinding] = []
        var nodes: [BrowserHydrationNodeRecord] = []
        nodes.reserveCapacity(artifact.graph.nodes.count)

        for index in artifact.graph.nodes.indices {
            let id = HTMLNodeID(index)
            let attributes = artifact.graph.attributes(of: id)
            let eventBindings = eventBindings(
                nodeID: id,
                attributes: attributes,
                handlerComponents: handlerComponents
            )
            allHandlers.append(contentsOf: eventBindings)

            nodes.append(BrowserHydrationNodeRecord(
                id: id,
                parentID: parentIDs[id],
                childIDs: artifact.graph.children(of: id),
                role: role(for: artifact.graph.node(id).kind),
                name: name(for: artifact.graph.node(id).kind, graph: artifact.graph),
                text: text(for: artifact.graph.node(id).kind, graph: artifact.graph),
                componentID: componentID(for: artifact.graph.node(id).kind),
                serverSlotID: serverSlotID(for: artifact.graph.node(id).kind),
                attributes: attributes,
                eventBindings: eventBindings,
                key: artifact.graph.node(id).key,
                fingerprint: artifact.graph.node(id).fingerprint
            ))
        }

        let components = artifact.hydration.components.map { component in
            BrowserHydrationComponentRecord(
                id: component.id,
                typeName: component.typeName,
                path: component.path,
                nodeID: component.nodeID,
                bundleID: component.bundleID,
                loadPolicy: component.loadPolicy,
                serverSlotIDs: component.serverSlots.map { $0.id },
                stateSlots: component.stateSlots,
                environmentSnapshot: component.environmentSnapshot
            )
        }

        let serverSlots = artifact.hydration.components.flatMap { $0.serverSlots }.sorted { left, right in
            left.id.rawValue < right.id.rawValue
        }

        return BrowserHydrationIndex(
            rootID: artifact.rootID,
            nodes: nodes,
            components: components,
            serverSlots: serverSlots,
            handlers: allHandlers
        )
    }

    private func parentIDs(in graph: HTMLGraph) -> [HTMLNodeID: HTMLNodeID] {
        var result: [HTMLNodeID: HTMLNodeID] = [:]
        for index in graph.nodes.indices {
            let parentID = HTMLNodeID(index)
            for childID in graph.children(of: parentID) {
                result[childID] = parentID
            }
        }
        return result
    }

    private func handlerComponents(in manifest: ClientHandlerManifest) -> [HandlerID: ComponentID] {
        var result: [HandlerID: ComponentID] = [:]
        for handler in manifest.handlers {
            if let componentID = handler.componentID {
                result[handler.id] = componentID
            }
        }
        return result
    }

    private func eventBindings(
        nodeID: HTMLNodeID,
        attributes: [HTMLAttributeRecord],
        handlerComponents: [HandlerID: ComponentID]
    ) -> [BrowserHydrationEventBinding] {
        attributes.compactMap { attribute in
            guard
                attribute.kind == .eventBinding,
                let handlerID = attribute.handlerID,
                let eventName = attribute.eventName
            else {
                return nil
            }

            return BrowserHydrationEventBinding(
                nodeID: nodeID,
                handlerID: handlerID,
                eventName: eventName,
                componentID: handlerComponents[handlerID]
            )
        }
    }

    private func role(for kind: HTMLNodeKind) -> BrowserHydrationNodeRole {
        switch kind {
        case .document:
            .document
        case .doctype:
            .doctype
        case .element:
            .element
        case .text:
            .text
        case .rawHTML:
            .rawHTML
        case .fragment:
            .fragment
        case .component:
            .component
        case .serverSlot:
            .serverSlot
        case .placeholder:
            .placeholder
        case .comment:
            .comment
        }
    }

    private func name(for kind: HTMLNodeKind, graph: HTMLGraph) -> String? {
        guard case .element(let stringID) = kind else {
            return nil
        }
        return graph.string(stringID)
    }

    private func text(for kind: HTMLNodeKind, graph: HTMLGraph) -> String? {
        switch kind {
        case .text(let id), .rawHTML(let id), .placeholder(let id), .comment(let id):
            graph.string(id)
        default:
            nil
        }
    }

    private func componentID(for kind: HTMLNodeKind) -> ComponentID? {
        guard case .component(let id) = kind else {
            return nil
        }
        return id
    }

    private func serverSlotID(for kind: HTMLNodeKind) -> ServerSlotID? {
        guard case .serverSlot(let id) = kind else {
            return nil
        }
        return id
    }
}
