/// A top-level entry in a `Stylesheet`: either a flat style rule or an at-rule.
///
/// At-rules (`@media`/`@supports`/`@starting-style`/`@keyframes`) are modeled
/// here as typed values so a stylesheet can express them without raw CSS
/// strings — the same "typed CSS is the single source of truth" contract the
/// flat `CSSRule` already provides.
public enum StylesheetItem: Sendable, Equatable {
    case rule(CSSRule)
    case media(String, Stylesheet)
    case supports(String, Stylesheet)
    case container(String, Stylesheet)
    case startingStyle(Stylesheet)
    case keyframes(String, [Keyframe])

    public var cssText: String {
        switch self {
        case .rule(let rule):
            return rule.cssText
        case .media(let query, let stylesheet):
            return Self.nested("@media \(query)", body: stylesheet.cssText)
        case .supports(let condition, let stylesheet):
            return Self.nested("@supports \(condition)", body: stylesheet.cssText)
        case .container(let query, let stylesheet):
            return Self.nested("@container \(query)", body: stylesheet.cssText)
        case .startingStyle(let stylesheet):
            return Self.nested("@starting-style", body: stylesheet.cssText)
        case .keyframes(let name, let frames):
            return Self.nested("@keyframes \(name)", body: frames.map { $0.cssText }.joined(separator: "\n"))
        }
    }

    private static func nested(_ prelude: String, body: String) -> String {
        let indented = body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "  \($0)" }
            .joined(separator: "\n")
        return "\(prelude) {\n\(indented)\n}"
    }
}

public func media(_ query: String, @StylesheetBuilder _ content: () -> Stylesheet) -> StylesheetItem {
    .media(query, content())
}

public func supports(_ condition: String, @StylesheetBuilder _ content: () -> Stylesheet) -> StylesheetItem {
    .supports(condition, content())
}

public func container(_ query: String, @StylesheetBuilder _ content: () -> Stylesheet) -> StylesheetItem {
    .container(query, content())
}

public func startingStyle(@StylesheetBuilder _ content: () -> Stylesheet) -> StylesheetItem {
    .startingStyle(content())
}

public func keyframes(_ name: String, _ frames: [Keyframe]) -> StylesheetItem {
    .keyframes(name, frames)
}

public func keyframes(_ name: String, @KeyframesBuilder _ content: () -> [Keyframe]) -> StylesheetItem {
    .keyframes(name, content())
}
