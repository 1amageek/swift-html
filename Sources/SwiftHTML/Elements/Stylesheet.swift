public struct Stylesheet: Sendable, Equatable {
    public var rules: [CSSRule]

    public init() {
        self.rules = []
    }

    public init(_ rules: [CSSRule]) {
        self.rules = rules
    }

    public init(_ rules: CSSRule...) {
        self.rules = rules
    }

    public init(@StylesheetBuilder _ content: () -> Stylesheet) {
        self = content()
    }

    public var cssText: String {
        rules.map(\.cssText).joined(separator: "\n")
    }
}
