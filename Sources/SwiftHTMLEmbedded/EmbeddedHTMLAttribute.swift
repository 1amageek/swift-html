public struct EmbeddedHTMLAttribute: Sendable, Equatable {
    public let name: String
    public let value: String

    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }

    public static func id(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("id", value)
    }

    public static func `class`(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("class", value)
    }

    public static func type(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("type", value)
    }

    public static func value(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("value", value)
    }

    public static func placeholder(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("placeholder", value)
    }

    public static func ariaLabel(_ value: String) -> EmbeddedHTMLAttribute {
        EmbeddedHTMLAttribute("aria-label", value)
    }
}
