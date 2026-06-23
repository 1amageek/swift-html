@resultBuilder
public enum EmbeddedHTMLBuilder {
    public static func buildBlock(_ components: [EmbeddedHTMLNode]...) -> [EmbeddedHTMLNode] {
        var result: [EmbeddedHTMLNode] = []
        for component in components {
            result.append(contentsOf: component)
        }
        return result
    }

    public static func buildExpression(_ expression: EmbeddedHTMLElement) -> [EmbeddedHTMLNode] {
        [.element(expression)]
    }

    public static func buildExpression(_ expression: EmbeddedHTMLNode) -> [EmbeddedHTMLNode] {
        [expression]
    }

    public static func buildExpression(_ expression: String) -> [EmbeddedHTMLNode] {
        [.text(expression)]
    }

    public static func buildExpression(_ expression: [EmbeddedHTMLNode]) -> [EmbeddedHTMLNode] {
        expression
    }

    public static func buildOptional(_ component: [EmbeddedHTMLNode]?) -> [EmbeddedHTMLNode] {
        component ?? []
    }

    public static func buildEither(first component: [EmbeddedHTMLNode]) -> [EmbeddedHTMLNode] {
        component
    }

    public static func buildEither(second component: [EmbeddedHTMLNode]) -> [EmbeddedHTMLNode] {
        component
    }

    public static func buildArray(_ components: [[EmbeddedHTMLNode]]) -> [EmbeddedHTMLNode] {
        var result: [EmbeddedHTMLNode] = []
        for component in components {
            result.append(contentsOf: component)
        }
        return result
    }
}
