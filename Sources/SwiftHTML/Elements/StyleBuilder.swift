@resultBuilder
public enum StyleBuilder {
    public static func buildBlock(_ components: Style...) -> Style {
        Style(components.flatMap(\.declarations))
    }

    public static func buildExpression(_ style: Style) -> Style {
        style
    }

    public static func buildOptional(_ component: Style?) -> Style {
        component ?? Style()
    }

    public static func buildEither(first component: Style) -> Style {
        component
    }

    public static func buildEither(second component: Style) -> Style {
        component
    }

    public static func buildArray(_ components: [Style]) -> Style {
        Style(components.flatMap(\.declarations))
    }

    public static func buildLimitedAvailability(_ component: Style) -> Style {
        component
    }
}
