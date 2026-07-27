@resultBuilder
public enum ComponentBuilder {
    public static func buildFinalResult(_ component: ComponentContent) -> ComponentContent {
        component
    }

    public static func buildBlock() -> ComponentContent {
        HTMLBuilder.buildBlock()
    }

    public static func buildBlock(_ component: ComponentContent) -> ComponentContent {
        component
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent,
        _ c5: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4, c5)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent,
        _ c5: ComponentContent,
        _ c6: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4, c5, c6)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent,
        _ c5: ComponentContent,
        _ c6: ComponentContent,
        _ c7: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent,
        _ c5: ComponentContent,
        _ c6: ComponentContent,
        _ c7: ComponentContent,
        _ c8: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    public static func buildBlock(
        _ c0: ComponentContent,
        _ c1: ComponentContent,
        _ c2: ComponentContent,
        _ c3: ComponentContent,
        _ c4: ComponentContent,
        _ c5: ComponentContent,
        _ c6: ComponentContent,
        _ c7: ComponentContent,
        _ c8: ComponentContent,
        _ c9: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildBlock(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
    }

    @_transparent
    public static func buildExpression<Content: Component>(
        _ expression: Content
    ) -> ComponentContent {
        HTMLBuilder.buildExpression(expression)
    }

    public static func buildExpression(_ expression: String) -> ComponentContent {
        HTMLBuilder.buildExpression(expression)
    }

    public static func buildExpression(_ expression: Int) -> ComponentContent {
        HTMLBuilder.buildExpression(expression)
    }

    public static func buildExpression(_ expression: Double) -> ComponentContent {
        HTMLBuilder.buildExpression(expression)
    }

    public static func buildExpression(_ expression: Bool) -> ComponentContent {
        HTMLBuilder.buildExpression(expression)
    }

    public static func buildOptional(
        _ component: ComponentContent?
    ) -> ComponentContent {
        HTMLBuilder.buildOptional(component)
    }

    public static func buildEither(
        first component: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildEither(first: component)
    }

    public static func buildEither(
        second component: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildEither(second: component)
    }

    public static func buildArray(
        _ components: [ComponentContent]
    ) -> ComponentContent {
        HTMLBuilder.buildArray(components)
    }

    public static func buildLimitedAvailability(
        _ component: ComponentContent
    ) -> ComponentContent {
        HTMLBuilder.buildLimitedAvailability(component)
    }
}
