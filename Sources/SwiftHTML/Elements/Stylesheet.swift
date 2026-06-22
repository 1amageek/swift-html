public struct Stylesheet: Sendable, Equatable {
    public var items: [StylesheetItem]

    public init() {
        self.items = []
    }

    public init(items: [StylesheetItem]) {
        self.items = items
    }

    public init(_ rules: [CSSRule]) {
        self.items = rules.map(StylesheetItem.rule)
    }

    public init(_ rules: CSSRule...) {
        self.items = rules.map(StylesheetItem.rule)
    }

    public init(@StylesheetBuilder _ content: () -> Stylesheet) {
        self = content()
    }

    /// The flat rules of this stylesheet, excluding at-rules. Provided for
    /// callers that only need the top-level style rules.
    public var rules: [CSSRule] {
        items.compactMap { item in
            if case .rule(let rule) = item { rule } else { nil }
        }
    }

    public var cssText: String {
        items.map(\.cssText).joined(separator: "\n")
    }
}
