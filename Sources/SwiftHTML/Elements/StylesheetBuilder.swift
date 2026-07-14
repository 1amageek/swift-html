@resultBuilder
public enum StylesheetBuilder {
    public static func buildBlock(_ components: Stylesheet...) -> Stylesheet {
        Stylesheet(items: components.flatMap { $0.items })
    }

    public static func buildExpression(_ rule: CSSRule) -> Stylesheet {
        Stylesheet(rule)
    }

    public static func buildExpression(_ item: StylesheetItem) -> Stylesheet {
        Stylesheet(items: [item])
    }

    public static func buildExpression(_ rules: [CSSRule]) -> Stylesheet {
        Stylesheet(rules)
    }

    public static func buildExpression(_ stylesheet: Stylesheet) -> Stylesheet {
        stylesheet
    }

    public static func buildOptional(_ component: Stylesheet?) -> Stylesheet {
        component ?? Stylesheet()
    }

    public static func buildEither(first component: Stylesheet) -> Stylesheet {
        component
    }

    public static func buildEither(second component: Stylesheet) -> Stylesheet {
        component
    }

    public static func buildArray(_ components: [Stylesheet]) -> Stylesheet {
        Stylesheet(items: components.flatMap { $0.items })
    }

    public static func buildLimitedAvailability(_ component: Stylesheet) -> Stylesheet {
        component
    }
}
