@dynamicMemberLookup
public struct Style: Sendable, Equatable {
    public private(set) var declarations: [Declaration]

    public init() {
        self.declarations = []
    }

    init(_ declarations: Declaration...) {
        self.declarations = declarations
    }

    init(_ declarations: [Declaration]) {
        self.declarations = declarations
    }

    public init(@StyleBuilder _ content: () -> Style) {
        self = content()
    }

    public var cssText: String {
        declarations.map(\.cssText).joined(separator: "; ")
    }

    public var isEmpty: Bool {
        declarations.isEmpty
    }
}

public extension Style {
    static subscript(dynamicMember member: String) -> (String) -> Style {
        { value in
            property(cssPropertyName(from: member), value)
        }
    }

    static func custom(_ property: String, _ value: String) -> Style {
        self.property(property, value)
    }

    internal static func property(_ property: String, _ value: String) -> Style {
        Style(Declaration(property, value))
    }

    subscript(dynamicMember member: String) -> (String) -> Style {
        { value in
            self.appending(Style.property(cssPropertyName(from: member), value))
        }
    }

    func custom(_ property: String, _ value: String) -> Style {
        appending(Style.property(property, value))
    }

    func appending(_ style: Style) -> Style {
        var nextDeclarations = declarations
        nextDeclarations.append(contentsOf: style.declarations)
        return Style(nextDeclarations)
    }

    mutating func append(_ style: Style) {
        declarations.append(contentsOf: style.declarations)
    }
}

public extension Style {
    struct Declaration: Sendable, Equatable {
        public let property: String
        public let value: String

        init(_ property: String, _ value: String) {
            self.property = property
            self.value = value
        }

        public var cssText: String {
            "\(property): \(value)"
        }
    }
}

private func cssPropertyName(from memberName: String) -> String {
    var result = ""
    for character in memberName {
        if character.isUppercase {
            if !result.isEmpty {
                result.append("-")
            }
            result.append(contentsOf: character.lowercased())
        } else {
            result.append(character)
        }
    }
    return result
}
