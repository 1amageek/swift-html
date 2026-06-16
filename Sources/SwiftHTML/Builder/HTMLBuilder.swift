@resultBuilder
public enum HTMLBuilder {
    public static func buildBlock() -> EmptyHTML {
        EmptyHTML()
    }

    public static func buildBlock<Content: HTML>(_ component: Content) -> Content {
        component
    }

    public static func buildBlock<First: HTML, Second: HTML, each Rest: HTML>(
        _ first: First,
        _ second: Second,
        _ rest: repeat each Rest
    ) -> TupleComponent<First, Second, repeat each Rest> {
        TupleComponent(first, second, repeat each rest)
    }

    public static func buildExpression<Content: HTML>(_ expression: Content) -> Content {
        expression
    }

    public static func buildExpression(_ expression: String) -> text {
        text(expression)
    }

    public static func buildExpression(_ expression: Int) -> text {
        text(String(expression))
    }

    public static func buildExpression(_ expression: Double) -> text {
        text(String(expression))
    }

    public static func buildExpression(_ expression: Bool) -> text {
        text(String(expression))
    }

    public static func buildOptional<Content: HTML>(_ component: Content?) -> OptionalComponent<Content> {
        OptionalComponent(component)
    }

    public static func buildEither<TrueContent: HTML, FalseContent: HTML>(
        first component: TrueContent
    ) -> ConditionalComponent<TrueContent, FalseContent> {
        .first(component)
    }

    public static func buildEither<TrueContent: HTML, FalseContent: HTML>(
        second component: FalseContent
    ) -> ConditionalComponent<TrueContent, FalseContent> {
        .second(component)
    }

    public static func buildArray<Content: HTML>(_ components: [Content]) -> ArrayComponent<Content> {
        ArrayComponent(components)
    }

    public static func buildLimitedAvailability<Content: HTML>(_ component: Content) -> Content {
        component
    }
}
