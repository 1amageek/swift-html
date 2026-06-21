/// Builds an attribute list declaratively, mirroring `StyleBuilder` for
/// declarations. It lets conditional and looped attributes be expressed with
/// `if`/`switch`/`for` instead of array concatenation such as
/// `(isOpen ? [.open] : []) + extra`.
///
/// A single `HTMLAttribute` and an existing `[HTMLAttribute]` are both valid
/// expressions, so existing attribute arrays can be spliced in directly.
@resultBuilder
public enum HTMLAttributeBuilder {
    public static func buildBlock(_ components: [HTMLAttribute]...) -> [HTMLAttribute] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ attribute: HTMLAttribute) -> [HTMLAttribute] {
        [attribute]
    }

    public static func buildExpression(_ attributes: [HTMLAttribute]) -> [HTMLAttribute] {
        attributes
    }

    public static func buildOptional(_ component: [HTMLAttribute]?) -> [HTMLAttribute] {
        component ?? []
    }

    public static func buildEither(first component: [HTMLAttribute]) -> [HTMLAttribute] {
        component
    }

    public static func buildEither(second component: [HTMLAttribute]) -> [HTMLAttribute] {
        component
    }

    public static func buildArray(_ components: [[HTMLAttribute]]) -> [HTMLAttribute] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [HTMLAttribute]) -> [HTMLAttribute] {
        component
    }
}
