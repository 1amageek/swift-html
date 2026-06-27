public func text(_ value: String) -> ClientHTMLNode {
    .text(value)
}

public func element(
    _ tagName: String,
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement(tagName, attributes: attributes, children: children())
}

public func main(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("main", attributes: attributes, children: children())
}

public func section(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("section", attributes: attributes, children: children())
}

public func div(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("div", attributes: attributes, children: children())
}

public func h1(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("h1", attributes: attributes, children: children())
}

public func p(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("p", attributes: attributes, children: children())
}

public func button(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("button", attributes: attributes, children: children())
}

public func output(
    _ attributes: ClientHTMLAttribute...,
    @ClientHTMLBuilder children: () -> [ClientHTMLNode]
) -> ClientHTMLElement {
    ClientHTMLElement("output", attributes: attributes, children: children())
}

public func input(_ attributes: ClientHTMLAttribute...) -> ClientHTMLElement {
    ClientHTMLElement("input", attributes: attributes, children: [])
}
