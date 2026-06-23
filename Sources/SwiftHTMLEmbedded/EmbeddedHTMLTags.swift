public func text(_ value: String) -> EmbeddedHTMLNode {
    .text(value)
}

public func element(
    _ tagName: String,
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement(tagName, attributes: attributes, children: children())
}

public func main(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("main", attributes: attributes, children: children())
}

public func section(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("section", attributes: attributes, children: children())
}

public func div(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("div", attributes: attributes, children: children())
}

public func h1(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("h1", attributes: attributes, children: children())
}

public func p(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("p", attributes: attributes, children: children())
}

public func button(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("button", attributes: attributes, children: children())
}

public func output(
    _ attributes: EmbeddedHTMLAttribute...,
    @EmbeddedHTMLBuilder children: () -> [EmbeddedHTMLNode]
) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("output", attributes: attributes, children: children())
}

public func input(_ attributes: EmbeddedHTMLAttribute...) -> EmbeddedHTMLElement {
    EmbeddedHTMLElement("input", attributes: attributes, children: [])
}
