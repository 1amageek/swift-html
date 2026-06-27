public struct ClientHTMLAttribute: Sendable, Equatable {
    public let name: String
    public let value: String

    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }

    public static func id(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("id", value)
    }

    public static func `class`(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("class", value)
    }

    public static func type(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("type", value)
    }

    public static func value(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("value", value)
    }

    public static func placeholder(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("placeholder", value)
    }

    public static func ariaLabel(_ value: String) -> ClientHTMLAttribute {
        ClientHTMLAttribute("aria-label", value)
    }
}
