public struct HTMLDOMSerializer: Sendable {
    public init() {}

    public func render(_ snapshot: HTMLDOMSnapshot) -> String {
        var writer = HTMLWriter(minimumCapacity: snapshot.nodes.count * 16)
        write(.node(snapshot.rootID), snapshot: snapshot, into: &writer)
        return writer.output
    }

    private func write(_ child: HTMLDOMChild, snapshot: HTMLDOMSnapshot, into writer: inout HTMLWriter) {
        switch child {
        case .html(let html):
            writer.write(html)
        case .node(let id):
            guard let node = snapshot.nodes[id] else {
                return
            }
            write(node, snapshot: snapshot, into: &writer)
        }
    }

    private func write(_ node: HTMLDOMNode, snapshot: HTMLDOMSnapshot, into writer: inout HTMLWriter) {
        switch node.kind {
        case .document:
            writer.write("<!doctype html>")
            writeChildren(of: node, snapshot: snapshot, into: &writer)
        case .doctype:
            writer.write("<!doctype html>")
        case .element(let name):
            let textareaValue = self.textareaValue(for: node)
            writer.write("<")
            writer.write(name)
            writeAttributes(of: node, elementName: name, into: &writer)
            writer.write(">")
            if node.flags.contains(.void) {
                return
            }
            if let textareaValue {
                writer.writeEscapedText(textareaValue)
            } else if isRawTextElement(name) {
                writeRawTextChildren(of: node, endTag: name, snapshot: snapshot, into: &writer)
            } else {
                writeChildren(of: node, snapshot: snapshot, into: &writer)
            }
            writer.write("</")
            writer.write(name)
            writer.write(">")
        case .text(let value):
            writer.writeEscapedText(value)
        case .rawHTML(let value), .opaqueHTML(let value):
            writer.write(value)
        case .fragment:
            writeChildren(of: node, snapshot: snapshot, into: &writer)
        case .component(let id):
            writer.write("<!--component:")
            writer.writeEscapedText(id.rawValue)
            writer.write(":begin-->")
            writeChildren(of: node, snapshot: snapshot, into: &writer)
            writer.write("<!--component:")
            writer.writeEscapedText(id.rawValue)
            writer.write(":end-->")
        case .serverSlot(let id):
            writer.write("<!--server-slot:")
            writer.writeEscapedText(id.rawValue)
            writer.write(":begin-->")
            writeChildren(of: node, snapshot: snapshot, into: &writer)
            writer.write("<!--server-slot:")
            writer.writeEscapedText(id.rawValue)
            writer.write(":end-->")
        case .placeholder(let value), .comment(let value):
            writer.write("<!--")
            writer.writeEscapedText(value)
            writer.write("-->")
        }
    }

    private func writeChildren(
        of node: HTMLDOMNode,
        snapshot: HTMLDOMSnapshot,
        into writer: inout HTMLWriter
    ) {
        for child in node.children {
            write(child, snapshot: snapshot, into: &writer)
        }
    }

    private func writeRawTextChildren(
        of node: HTMLDOMNode,
        endTag: String,
        snapshot: HTMLDOMSnapshot,
        into writer: inout HTMLWriter
    ) {
        for child in node.children {
            writeRawText(child, endTag: endTag, snapshot: snapshot, into: &writer)
        }
    }

    private func writeRawText(
        _ child: HTMLDOMChild,
        endTag: String,
        snapshot: HTMLDOMSnapshot,
        into writer: inout HTMLWriter
    ) {
        switch child {
        case .html(let html):
            writer.write(escapeRawText(html, endTag: endTag))
        case .node(let id):
            guard let node = snapshot.nodes[id] else {
                return
            }
            switch node.kind {
            case .text(let value), .rawHTML(let value), .opaqueHTML(let value):
                writer.write(escapeRawText(value, endTag: endTag))
            case .fragment:
                writeRawTextChildren(of: node, endTag: endTag, snapshot: snapshot, into: &writer)
            default:
                write(node, snapshot: snapshot, into: &writer)
            }
        }
    }

    private func writeAttributes(
        of node: HTMLDOMNode,
        elementName: String,
        into writer: inout HTMLWriter
    ) {
        for attribute in node.attributes {
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

    private func textareaValue(for node: HTMLDOMNode) -> String? {
        guard case .element("textarea") = node.kind else {
            return nil
        }
        return node.attributes.first { attribute in
            isTextareaValueBinding(attribute, elementName: "textarea")
        }?.value ?? nil
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
