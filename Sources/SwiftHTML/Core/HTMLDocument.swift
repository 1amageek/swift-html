/// A complete HTML document with explicit head and body sections.
///
/// Documents conform to ``HTML`` so they use the same renderer as components,
/// but they do not conform to ``Component`` and therefore cannot be nested
/// inside elements or component content.
public protocol HTMLDocument: HTML {
    associatedtype Head: Component
    associatedtype Body: Component

    var htmlAttributes: [HTMLAttribute] { get }

    @HTMLBuilder
    var head: Head { get }

    var bodyAttributes: [HTMLAttribute] { get }

    @HTMLBuilder
    var body: Body { get }
}

public extension HTMLDocument {
    var htmlAttributes: [HTMLAttribute] { [] }
    var bodyAttributes: [HTMLAttribute] { [] }

    static func _buildNode(
        _ html: Self,
        in builder: inout HTMLGraphBuilder
    ) -> HTMLNodeID {
        builder.buildDocumentNode(html)
    }
}

/// A closure-built concrete ``HTMLDocument``.
public struct Document<Head: Component, Body: Component>: HTMLDocument {
    public let htmlAttributes: [HTMLAttribute]
    public let head: Head
    public let bodyAttributes: [HTMLAttribute]
    public let body: Body

    public init(
        htmlAttributes: [HTMLAttribute] = [],
        bodyAttributes: [HTMLAttribute] = [],
        @HTMLBuilder head: () -> Head,
        @HTMLBuilder body: () -> Body
    ) {
        self.htmlAttributes = htmlAttributes
        self.head = head()
        self.bodyAttributes = bodyAttributes
        self.body = body()
    }
}
