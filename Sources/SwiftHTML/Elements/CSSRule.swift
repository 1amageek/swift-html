public struct CSSRule: Sendable, Equatable {
    public let selector: CSSSelector
    public let style: Style

    public init(_ selector: CSSSelector, style: Style) {
        self.selector = selector
        self.style = style
    }

    public init(_ selector: CSSSelector, @StyleBuilder _ style: () -> Style) {
        self.init(selector, style: style())
    }

    public var cssText: String {
        if style.declarations.isEmpty {
            return "\(selector.cssText) {}"
        }

        let declarations = style.declarations
            .map { declaration in "  \(declaration.cssText);" }
            .joined(separator: "\n")
        return "\(selector.cssText) {\n\(declarations)\n}"
    }
}

public func rule(_ selector: String, @StyleBuilder _ style: () -> Style) -> CSSRule {
    CSSRule(CSSSelector(selector), style: style())
}

public func rule(_ selector: String, _ style: Style) -> CSSRule {
    CSSRule(CSSSelector(selector), style: style)
}
