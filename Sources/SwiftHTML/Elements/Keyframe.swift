/// A single keyframe stop inside an `@keyframes` rule, e.g. `from`, `to`, or
/// `50%`. Multiple stops may share a selector list (`"0%, 100%"`).
public struct Keyframe: Sendable, Equatable {
    public let selector: String
    public let style: Style

    public init(_ selector: String, style: Style) {
        self.selector = selector
        self.style = style
    }

    public init(_ selector: String, @StyleBuilder _ style: () -> Style) {
        self.init(selector, style: style())
    }

    public var cssText: String {
        if style.declarations.isEmpty {
            return "\(selector) {}"
        }
        let declarations = style.declarations
            .map { "  \($0.cssText);" }
            .joined(separator: "\n")
        return "\(selector) {\n\(declarations)\n}"
    }
}

@resultBuilder
public enum KeyframesBuilder {
    public static func buildBlock(_ components: [Keyframe]...) -> [Keyframe] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ keyframe: Keyframe) -> [Keyframe] {
        [keyframe]
    }

    public static func buildExpression(_ keyframes: [Keyframe]) -> [Keyframe] {
        keyframes
    }

    public static func buildOptional(_ component: [Keyframe]?) -> [Keyframe] {
        component ?? []
    }

    public static func buildEither(first component: [Keyframe]) -> [Keyframe] {
        component
    }

    public static func buildEither(second component: [Keyframe]) -> [Keyframe] {
        component
    }

    public static func buildArray(_ components: [[Keyframe]]) -> [Keyframe] {
        components.flatMap { $0 }
    }
}
