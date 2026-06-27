@resultBuilder
public enum ClientHTMLBuilder {
    public static func buildBlock(_ components: [ClientHTMLNode]...) -> [ClientHTMLNode] {
        var result: [ClientHTMLNode] = []
        for component in components {
            result.append(contentsOf: component)
        }
        return result
    }

    public static func buildExpression(_ expression: ClientHTMLElement) -> [ClientHTMLNode] {
        [.element(expression)]
    }

    public static func buildExpression(_ expression: ClientHTMLNode) -> [ClientHTMLNode] {
        [expression]
    }

    public static func buildExpression(_ expression: String) -> [ClientHTMLNode] {
        [.text(expression)]
    }

    public static func buildExpression(_ expression: [ClientHTMLNode]) -> [ClientHTMLNode] {
        expression
    }

    public static func buildOptional(_ component: [ClientHTMLNode]?) -> [ClientHTMLNode] {
        component ?? []
    }

    public static func buildEither(first component: [ClientHTMLNode]) -> [ClientHTMLNode] {
        component
    }

    public static func buildEither(second component: [ClientHTMLNode]) -> [ClientHTMLNode] {
        component
    }

    public static func buildArray(_ components: [[ClientHTMLNode]]) -> [ClientHTMLNode] {
        var result: [ClientHTMLNode] = []
        for component in components {
            result.append(contentsOf: component)
        }
        return result
    }
}
