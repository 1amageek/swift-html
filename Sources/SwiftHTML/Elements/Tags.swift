public protocol ContainerElement: ElementRepresentable {
    static var tagName: String { get }
}

public protocol VoidElement: ElementRepresentable {
    static var tagName: String { get }
}

public extension ContainerElement {
    init(_ attributes: HTMLAttribute...) {
        self.init(Element(Self.tagName, attributes: attributes))
    }

    init(_ value: String) {
        self.init(Element(Self.tagName, attributes: []) {
            text(value)
        })
    }

    init(_ attributes: HTMLAttribute..., text value: String) {
        self.init(Element(Self.tagName, attributes: attributes) {
            text(value)
        })
    }

    init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.init(Element(Self.tagName, attributes: []) { content() })
    }

    init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.init(Element(Self.tagName, attributes: attributes) { content() })
    }

    init<Content: HTML>(
        @HTMLAttributeBuilder attributes: () -> [HTMLAttribute],
        @HTMLBuilder content: () -> Content
    ) {
        self.init(Element(Self.tagName, attributes: attributes()) { content() })
    }
}

public extension VoidElement {
    init(_ attributes: HTMLAttribute...) {
        self.init(Element(Self.tagName, attributes: attributes, isVoid: true))
    }

    init(@HTMLAttributeBuilder attributes: () -> [HTMLAttribute]) {
        self.init(Element(Self.tagName, attributes: attributes(), isVoid: true))
    }
}

public struct document: HTMLPrimitive {
    let children: [HTMLContent]

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.children = [HTMLContent(content())]
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(children.count)
        for (index, child) in children.enumerated() {
            childIDs.append(builder.withPathSegment("document:\(index)") { scopedBuilder in
                child.buildNode(in: &scopedBuilder)
            })
        }
        return builder.addNode(kind: .document, children: childIDs)
    }
}

public struct doctype: HTMLPrimitive {
    public init() {}

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.addNode(kind: .doctype, children: [])
    }
}

public struct comment: HTMLPrimitive {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.addNode(kind: .comment(builder.intern(value)), children: [])
    }
}

public struct html: ContainerElement {
    public static let tagName = "html"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct head: ContainerElement {
    public static let tagName = "head"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct body: ContainerElement {
    public static let tagName = "body"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct title: ContainerElement {
    public static let tagName = "title"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct base: VoidElement {
    public static let tagName = "base"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct link: VoidElement {
    public static let tagName = "link"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct meta: VoidElement {
    public static let tagName = "meta"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct style: ContainerElement {
    public static let tagName = "style"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct script: ContainerElement {
    public static let tagName = "script"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct main: ContainerElement {
    public static let tagName = "main"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct section: ContainerElement {
    public static let tagName = "section"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct nav: ContainerElement {
    public static let tagName = "nav"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct article: ContainerElement {
    public static let tagName = "article"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct aside: ContainerElement {
    public static let tagName = "aside"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct header: ContainerElement {
    public static let tagName = "header"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct footer: ContainerElement {
    public static let tagName = "footer"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct address: ContainerElement {
    public static let tagName = "address"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h1: ContainerElement {
    public static let tagName = "h1"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h2: ContainerElement {
    public static let tagName = "h2"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h3: ContainerElement {
    public static let tagName = "h3"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h4: ContainerElement {
    public static let tagName = "h4"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h5: ContainerElement {
    public static let tagName = "h5"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct h6: ContainerElement {
    public static let tagName = "h6"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct p: ContainerElement {
    public static let tagName = "p"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct hr: VoidElement {
    public static let tagName = "hr"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct pre: ContainerElement {
    public static let tagName = "pre"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct blockquote: ContainerElement {
    public static let tagName = "blockquote"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct ol: ContainerElement {
    public static let tagName = "ol"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct ul: ContainerElement {
    public static let tagName = "ul"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct li: ContainerElement {
    public static let tagName = "li"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct dl: ContainerElement {
    public static let tagName = "dl"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct dt: ContainerElement {
    public static let tagName = "dt"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct dd: ContainerElement {
    public static let tagName = "dd"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct figure: ContainerElement {
    public static let tagName = "figure"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct figcaption: ContainerElement {
    public static let tagName = "figcaption"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct div: ContainerElement {
    public static let tagName = "div"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct a: ContainerElement {
    public static let tagName = "a"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct em: ContainerElement {
    public static let tagName = "em"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct strong: ContainerElement {
    public static let tagName = "strong"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct small: ContainerElement {
    public static let tagName = "small"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct s: ContainerElement {
    public static let tagName = "s"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct cite: ContainerElement {
    public static let tagName = "cite"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct q: ContainerElement {
    public static let tagName = "q"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct dfn: ContainerElement {
    public static let tagName = "dfn"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct abbr: ContainerElement {
    public static let tagName = "abbr"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct code: ContainerElement {
    public static let tagName = "code"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct varElement: ContainerElement {
    public static let tagName = "var"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct samp: ContainerElement {
    public static let tagName = "samp"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct kbd: ContainerElement {
    public static let tagName = "kbd"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct sub: ContainerElement {
    public static let tagName = "sub"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct sup: ContainerElement {
    public static let tagName = "sup"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct i: ContainerElement {
    public static let tagName = "i"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct b: ContainerElement {
    public static let tagName = "b"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct u: ContainerElement {
    public static let tagName = "u"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct mark: ContainerElement {
    public static let tagName = "mark"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct ruby: ContainerElement {
    public static let tagName = "ruby"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct rt: ContainerElement {
    public static let tagName = "rt"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct rp: ContainerElement {
    public static let tagName = "rp"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct bdi: ContainerElement {
    public static let tagName = "bdi"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct bdo: ContainerElement {
    public static let tagName = "bdo"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct span: ContainerElement {
    public static let tagName = "span"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct br: VoidElement {
    public static let tagName = "br"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct wbr: VoidElement {
    public static let tagName = "wbr"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct ins: ContainerElement {
    public static let tagName = "ins"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct del: ContainerElement {
    public static let tagName = "del"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct picture: ContainerElement {
    public static let tagName = "picture"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct source: VoidElement {
    public static let tagName = "source"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct img: VoidElement {
    public static let tagName = "img"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct iframe: ContainerElement {
    public static let tagName = "iframe"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct embed: VoidElement {
    public static let tagName = "embed"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct object: ContainerElement {
    public static let tagName = "object"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct param: VoidElement {
    public static let tagName = "param"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct video: ContainerElement {
    public static let tagName = "video"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct audio: ContainerElement {
    public static let tagName = "audio"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct track: VoidElement {
    public static let tagName = "track"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct map: ContainerElement {
    public static let tagName = "map"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct area: VoidElement {
    public static let tagName = "area"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct table: ContainerElement {
    public static let tagName = "table"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct caption: ContainerElement {
    public static let tagName = "caption"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct colgroup: ContainerElement {
    public static let tagName = "colgroup"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct col: VoidElement {
    public static let tagName = "col"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct tbody: ContainerElement {
    public static let tagName = "tbody"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct thead: ContainerElement {
    public static let tagName = "thead"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct tfoot: ContainerElement {
    public static let tagName = "tfoot"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct tr: ContainerElement {
    public static let tagName = "tr"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct td: ContainerElement {
    public static let tagName = "td"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct th: ContainerElement {
    public static let tagName = "th"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct form: ContainerElement {
    public static let tagName = "form"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct label: ContainerElement {
    public static let tagName = "label"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct input: VoidElement {
    public static let tagName = "input"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes, isVoid: true)
    }
}

public struct button: ContainerElement {
    public static let tagName = "button"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct select: ContainerElement {
    public static let tagName = "select"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct datalist: ContainerElement {
    public static let tagName = "datalist"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct optgroup: ContainerElement {
    public static let tagName = "optgroup"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct option: ContainerElement {
    public static let tagName = "option"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct textarea: ContainerElement {
    public static let tagName = "textarea"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct output: ContainerElement {
    public static let tagName = "output"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct progress: ContainerElement {
    public static let tagName = "progress"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct meter: ContainerElement {
    public static let tagName = "meter"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct fieldset: ContainerElement {
    public static let tagName = "fieldset"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct legend: ContainerElement {
    public static let tagName = "legend"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct details: ContainerElement {
    public static let tagName = "details"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct summary: ContainerElement {
    public static let tagName = "summary"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct dialog: ContainerElement {
    public static let tagName = "dialog"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct canvas: ContainerElement {
    public static let tagName = "canvas"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct noscript: ContainerElement {
    public static let tagName = "noscript"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}

public struct template: ContainerElement {
    public static let tagName = "template"
    public let element: Element
    public init(_ element: Element) { self.element = element }
    public init(_ attributes: HTMLAttribute...) {
        self.element = Element(Self.tagName, attributes: attributes)
    }

    public init<Content: HTML>(@HTMLBuilder _ content: () -> Content) {
        self.element = Element(Self.tagName, attributes: []) { content() }
    }

    public init<Content: HTML>(_ attributes: HTMLAttribute..., @HTMLBuilder content: () -> Content) {
        self.element = Element(Self.tagName, attributes: attributes) { content() }
    }
}
