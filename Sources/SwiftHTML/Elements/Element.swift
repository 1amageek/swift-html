public protocol ElementRepresentable: HTML {
    var element: Element { get }

    init(_ element: Element)
}

public extension ElementRepresentable {
    func attribute(_ attribute: HTMLAttribute) -> Self {
        Self(element.adding(attribute))
    }

    func attribute(_ name: String, _ value: String? = nil) -> Self {
        attribute(.attribute(name, value))
    }

    func attributes(_ attributes: [HTMLAttribute]) -> Self {
        Self(element.adding(attributes))
    }

    func id(_ value: String) -> Self {
        attribute(.id(value))
    }

    func `class`(_ value: String) -> Self {
        attribute(.class(value))
    }

    func style(_ value: String) -> Self {
        attribute(.style(value))
    }

    func style(_ style: Style) -> Self {
        attribute(.style(style))
    }

    func style(@StyleBuilder _ content: () -> Style) -> Self {
        style(content())
    }

    func data(_ name: String, _ value: String) -> Self {
        attribute(.data(name, value))
    }

    func aria(_ name: String, _ value: String) -> Self {
        attribute(.aria(name, value))
    }

    func role(_ value: String) -> Self {
        attribute(.role(value))
    }

    func hidden(_ condition: Bool = true) -> Self {
        condition ? attribute(.hidden) : self
    }

    func disabled(_ condition: Bool = true) -> Self {
        condition ? attribute(.disabled) : self
    }

    func key<ID: Hashable & Sendable>(_ value: ID) -> Self {
        Self(element.withKey(Key(value)))
    }

    func on(_ eventName: String, _ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.event(eventName, handler))
    }

    func onClick(_ handler: @escaping () -> Void) -> Self {
        attribute(.onClick(handler))
    }

    func onClick(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onClick(handler))
    }

    func onInput(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onInput(handler))
    }

    func onChange(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onChange(handler))
    }

    func onSubmit(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onSubmit(handler))
    }

    func onKeyDown(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onKeyDown(handler))
    }

    func onKeyUp(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onKeyUp(handler))
    }

    func onFocus(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onFocus(handler))
    }

    func onBlur(_ handler: @escaping (DOMEvent) -> Void) -> Self {
        attribute(.onBlur(handler))
    }
}

public struct Element: ElementRepresentable, HTMLPrimitive {
    public let name: String
    public let attributes: [HTMLAttribute]
    public let isVoid: Bool
    public let nodeKey: Key?
    let children: [HTMLContent]

    public var element: Element {
        self
    }

    public init(_ element: Element) {
        self = element
    }

    public init(
        _ name: String,
        attributes: [HTMLAttribute] = [],
        isVoid: Bool = false,
        key: Key? = nil
    ) {
        self.name = name
        self.attributes = attributes
        self.children = []
        self.isVoid = isVoid
        self.nodeKey = key
    }

    init(
        _ name: String,
        attributes: [HTMLAttribute],
        isVoid: Bool = false,
        key: Key? = nil,
        children: [HTMLContent]
    ) {
        self.name = name
        self.attributes = attributes
        self.children = children
        self.isVoid = isVoid
        self.nodeKey = key
    }

    public init(_ name: String, _ attributes: HTMLAttribute...) {
        self.init(name, attributes: attributes)
    }

    public init(_ name: String, text value: String) {
        self.init(name, attributes: [], children: [HTMLContent(text(value))])
    }

    public init(_ name: String, attributes: [HTMLAttribute], text value: String) {
        self.init(name, attributes: attributes, children: [HTMLContent(text(value))])
    }

    public init<Content: HTML>(
        _ name: String,
        @HTMLBuilder _ content: () -> Content
    ) {
        self.init(name, attributes: [], children: [HTMLContent(content())])
    }

    public init<Content: HTML>(
        _ name: String,
        _ attributes: HTMLAttribute...,
        @HTMLBuilder content: () -> Content
    ) {
        self.init(name, attributes: attributes, children: [HTMLContent(content())])
    }

    public init<Content: HTML>(
        _ name: String,
        attributes: [HTMLAttribute],
        isVoid: Bool = false,
        @HTMLBuilder content: () -> Content
    ) {
        self.init(name, attributes: attributes, isVoid: isVoid, children: [HTMLContent(content())])
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        guard HTMLGraphBuilder.isValidHTMLName(name) else {
            return builder.addInvalidElement(name: name)
        }

        var childIDs: [HTMLNodeID] = []
        if !isVoid {
            childIDs.reserveCapacity(children.count)
            for (index, child) in children.enumerated() {
                childIDs.append(builder.withPathSegment("child:\(index)") { scopedBuilder in
                    child.buildNode(in: &scopedBuilder)
                })
            }
        }
        return builder.addNode(
            kind: .element(builder.intern(name)),
            attributes: attributes,
            children: childIDs,
            flags: isVoid ? .void : [],
            key: nodeKey
        )
    }

    func adding(_ attribute: HTMLAttribute) -> Element {
        adding([attribute])
    }

    func adding(_ attributes: [HTMLAttribute]) -> Element {
        Element(
            name,
            attributes: self.attributes + attributes,
            isVoid: isVoid,
            key: nodeKey,
            children: children
        )
    }

    func withKey(_ key: Key) -> Element {
        Element(
            name,
            attributes: attributes,
            isVoid: isVoid,
            key: key,
            children: children
        )
    }
}
