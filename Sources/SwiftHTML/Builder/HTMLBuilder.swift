@resultBuilder
public enum HTMLBuilder {
    public static func buildBlock() -> EmptyHTML {
        EmptyHTML()
    }

    public static func buildBlock<Content: HTML>(_ component: Content) -> Content {
        component
    }

    public static func buildBlock<C0: HTML, C1: HTML>(
        _ c0: C0,
        _ c1: C1
    ) -> TupleComponent2<C0, C1> {
        TupleComponent2(c0, c1)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> TupleComponent3<C0, C1, C2> {
        TupleComponent3(c0, c1, c2)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3
    ) -> TupleComponent4<C0, C1, C2, C3> {
        TupleComponent4(c0, c1, c2, c3)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4
    ) -> TupleComponent5<C0, C1, C2, C3, C4> {
        TupleComponent5(c0, c1, c2, c3, c4)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5
    ) -> TupleComponent6<C0, C1, C2, C3, C4, C5> {
        TupleComponent6(c0, c1, c2, c3, c4, c5)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6
    ) -> TupleComponent7<C0, C1, C2, C3, C4, C5, C6> {
        TupleComponent7(c0, c1, c2, c3, c4, c5, c6)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7
    ) -> TupleComponent8<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleComponent8(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML, C8: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8
    ) -> TupleComponent9<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleComponent9(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    public static func buildBlock<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML, C8: HTML, C9: HTML>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8,
        _ c9: C9
    ) -> TupleComponent10<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleComponent10(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
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
