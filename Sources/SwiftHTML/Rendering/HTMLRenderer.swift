import Foundation

public struct HTMLRenderer: Sendable {
    public init() {}

    public func render(
        _ html: some HTML,
        environment: EnvironmentValues = EnvironmentValues(),
        stateStore: StateStore = StateStore(),
        options: HTMLRenderOptions = .development
    ) -> RenderArtifact {
        var builder = HTMLGraphBuilder(environment: environment, stateStore: stateStore, options: options)
        let root = builder.append(html)
        var writer = HTMLWriter(minimumCapacity: estimatedOutputLength(for: builder.graph))
        write(root, graph: builder.graph, options: options, into: &writer)
        return RenderArtifact(
            html: writer.output,
            graph: builder.graph,
            rootID: root,
            hydration: builder.hydration,
            clientHandlers: builder.clientHandlers,
            diagnostics: builder.diagnostics
        )
    }

    func renderSubtree(
        _ id: HTMLNodeID,
        graph: HTMLGraph,
        options: HTMLRenderOptions = .development
    ) -> String {
        var writer = HTMLWriter(minimumCapacity: estimatedOutputLength(for: graph))
        write(id, graph: graph, options: options, into: &writer)
        return writer.output
    }

    private func estimatedOutputLength(for graph: HTMLGraph) -> Int {
        let stringBytes = graph.strings.reduce(0) { partial, value in
            partial + value.count
        }
        return stringBytes + graph.nodes.count * 12 + graph.attributes.count * 16
    }

    private func write(
        _ id: HTMLNodeID,
        graph: HTMLGraph,
        options: HTMLRenderOptions,
        into writer: inout HTMLWriter
    ) {
        let node = graph.nodes[id.rawValue]
        switch node.kind {
        case .document:
            writer.write("<!doctype html>")
            writeChildren(of: node, graph: graph, options: options, into: &writer)
        case .doctype:
            writer.write("<!doctype html>")
        case .element(let nameID):
            let name = graph.strings[nameID.rawValue]
            let textareaValue = self.textareaValue(for: node, graph: graph)
            writer.write("<")
            writer.write(name)
            writeAttributes(of: node, nodeID: id, elementName: name, graph: graph, options: options, into: &writer)
            writer.write(">")
            if node.flags.contains(.void) {
                return
            }
            if let textareaValue {
                writer.writeEscapedText(textareaValue)
            } else if isRawTextElement(name) {
                writeRawTextChildren(of: node, endTag: name, graph: graph, into: &writer)
            } else {
                writeChildren(of: node, graph: graph, options: options, into: &writer)
            }
            writer.write("</")
            writer.write(name)
            writer.write(">")
        case .text(let stringID):
            writer.writeEscapedText(graph.strings[stringID.rawValue])
        case .rawHTML(let stringID):
            writer.write(graph.strings[stringID.rawValue])
        case .fragment:
            writeChildren(of: node, graph: graph, options: options, into: &writer)
        case .component(let componentID):
            writer.write("<!--swift-html-component:")
            writer.writeEscapedText(componentID.rawValue)
            writer.write(":begin-->")
            writeChildren(of: node, graph: graph, options: options, into: &writer)
            writer.write("<!--swift-html-component:")
            writer.writeEscapedText(componentID.rawValue)
            writer.write(":end-->")
        case .serverSlot(let slotID):
            writer.write("<!--swift-html-server-slot:")
            writer.writeEscapedText(slotID.rawValue)
            writer.write(":begin-->")
            writeChildren(of: node, graph: graph, options: options, into: &writer)
            writer.write("<!--swift-html-server-slot:")
            writer.writeEscapedText(slotID.rawValue)
            writer.write(":end-->")
        case .placeholder(let stringID):
            writer.write("<!--")
            writer.writeEscapedText(graph.strings[stringID.rawValue])
            writer.write("-->")
        case .comment(let stringID):
            writer.write("<!--")
            writer.writeEscapedText(graph.strings[stringID.rawValue])
            writer.write("-->")
        }
    }

    private func writeChildren(
        of node: HTMLNodeRecord,
        graph: HTMLGraph,
        options: HTMLRenderOptions,
        into writer: inout HTMLWriter
    ) {
        let end = node.firstChild + node.childCount
        for index in node.firstChild..<end {
            write(graph.edges[index], graph: graph, options: options, into: &writer)
        }
    }

    private func writeRawTextChildren(
        of node: HTMLNodeRecord,
        endTag: String,
        graph: HTMLGraph,
        into writer: inout HTMLWriter
    ) {
        let end = node.firstChild + node.childCount
        for index in node.firstChild..<end {
            writeRawText(graph.edges[index], endTag: endTag, graph: graph, into: &writer)
        }
    }

    private func writeRawText(_ id: HTMLNodeID, endTag: String, graph: HTMLGraph, into writer: inout HTMLWriter) {
        let node = graph.nodes[id.rawValue]
        switch node.kind {
        case .text(let stringID), .rawHTML(let stringID):
            writer.write(escapeRawText(graph.strings[stringID.rawValue], endTag: endTag))
        case .fragment:
            writeRawTextChildren(of: node, endTag: endTag, graph: graph, into: &writer)
        default:
            write(id, graph: graph, options: .development, into: &writer)
        }
    }

    private func writeAttributes(
        of node: HTMLNodeRecord,
        nodeID: HTMLNodeID,
        elementName: String,
        graph: HTMLGraph,
        options: HTMLRenderOptions,
        into writer: inout HTMLWriter
    ) {
        let end = node.firstAttribute + node.attributeCount
        let attributes = Array(graph.attributes[node.firstAttribute..<end])
        if options.emitsBrowserHydrationMarkers && !attributes.contains(where: { $0.name == "data-swift-node" }) {
            writer.write(" data-swift-node=\"")
            writer.writeEscapedAttribute(String(nodeID.rawValue))
            writer.write("\"")
        }
        if options.emitsBrowserHydrationMarkers,
           let key = node.key,
           !attributes.contains(where: { $0.name == "data-swift-key" }) {
            writer.write(" data-swift-key=\"")
            writer.writeEscapedAttribute(key.identity)
            writer.write("\"")
        }
        for index in node.firstAttribute..<end {
            let attribute = graph.attributes[index]
            if isFalseBooleanPropertyBinding(attribute) {
                continue
            }
            if isTextareaValueBinding(attribute, elementName: elementName) {
                continue
            }

            writer.write(" ")
            writer.write(attribute.name)
            if isTrueBooleanPropertyBinding(attribute) {
                continue
            }

            guard let value = attribute.value else {
                continue
            }
            writer.write("=\"")
            writer.writeEscapedAttribute(value)
            writer.write("\"")
        }
    }

    private func textareaValue(for node: HTMLNodeRecord, graph: HTMLGraph) -> String? {
        guard case .element(let nameID) = node.kind, graph.string(nameID) == "textarea" else {
            return nil
        }

        let end = node.firstAttribute + node.attributeCount
        for index in node.firstAttribute..<end {
            let attribute = graph.attributes[index]
            if isTextareaValueBinding(attribute, elementName: "textarea") {
                return attribute.value ?? ""
            }
        }
        return nil
    }

    private func isTextareaValueBinding(_ attribute: HTMLAttributeRecord, elementName: String) -> Bool {
        elementName == "textarea"
            && attribute.kind == .propertyBinding
            && attribute.name == "value"
    }

    private func isFalseBooleanPropertyBinding(_ attribute: HTMLAttributeRecord) -> Bool {
        attribute.kind == .propertyBinding
            && isBooleanAttribute(attribute.name)
            && attribute.value == "false"
    }

    private func isTrueBooleanPropertyBinding(_ attribute: HTMLAttributeRecord) -> Bool {
        attribute.kind == .propertyBinding
            && isBooleanAttribute(attribute.name)
            && attribute.value == "true"
    }

    private func isBooleanAttribute(_ name: String) -> Bool {
        switch name {
        case "allowfullscreen",
             "async",
             "autofocus",
             "autoplay",
             "checked",
             "controls",
             "default",
             "defer",
             "disabled",
             "formnovalidate",
             "hidden",
             "inert",
             "ismap",
             "itemscope",
             "loop",
             "multiple",
             "muted",
             "nomodule",
             "novalidate",
             "open",
             "playsinline",
             "readonly",
             "required",
             "reversed",
             "selected":
            true
        default:
            false
        }
    }

    private func isRawTextElement(_ name: String) -> Bool {
        switch name {
        case "script", "style":
            true
        default:
            false
        }
    }

    private func escapeRawText(_ value: String, endTag: String) -> String {
        var output = value
        let closingTagPrefix = "</\(endTag)"
        while let range = output.range(of: closingTagPrefix, options: [.caseInsensitive]) {
            output.replaceSubrange(range, with: "<\\/\(endTag)")
        }
        return output
    }
}

public extension HTML {
    func render() -> String {
        HTMLRenderer().render(self).html
    }

    func render(environment: EnvironmentValues) -> String {
        HTMLRenderer().render(self, environment: environment).html
    }

    func render(stateStore: StateStore) -> String {
        HTMLRenderer().render(self, stateStore: stateStore).html
    }

    func renderArtifact(
        environment: EnvironmentValues = EnvironmentValues(),
        stateStore: StateStore = StateStore(),
        options: HTMLRenderOptions = .development
    ) -> RenderArtifact {
        HTMLRenderer().render(self, environment: environment, stateStore: stateStore, options: options)
    }
}
