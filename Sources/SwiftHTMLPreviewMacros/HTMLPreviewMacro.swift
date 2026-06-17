import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct HTMLPreviewMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let closure = contentClosure(in: node) else {
            context.diagnose(node: Syntax(node), message: "#HTMLPreview requires a trailing HTML builder closure")
            return []
        }

        let titleExpression = previewTitleExpression(in: node)
        let configurationExpression = previewConfigurationExpression(in: node)
        let previewArguments = previewArguments(in: node)
        let hostArguments = hostArguments(
            titleExpression: titleExpression,
            configurationExpression: configurationExpression
        )
        let content = indent(normalizedStatements(closure.statements.trimmedDescription), by: 8)

        return [
            DeclSyntax(stringLiteral: """
            #Preview\(previewArguments) {
                SwiftHTMLPreview.HTMLPreviewHost\(hostArguments) {
            \(content)
                }
            }
            """),
        ]
    }

    private static func contentClosure(in node: some FreestandingMacroExpansionSyntax) -> ClosureExprSyntax? {
        if let trailingClosure = node.trailingClosure {
            return trailingClosure
        }

        for argument in node.arguments {
            guard argument.label?.text == "content",
                  let closure = argument.expression.as(ClosureExprSyntax.self) else {
                continue
            }
            return closure
        }

        return nil
    }

    private static func previewTitleExpression(in node: some FreestandingMacroExpansionSyntax) -> String? {
        guard let argument = node.arguments.first,
              argument.label == nil,
              !argument.expression.is(ClosureExprSyntax.self) else {
            return nil
        }

        return argument.expression.trimmedDescription
    }

    private static func previewConfigurationExpression(in node: some FreestandingMacroExpansionSyntax) -> String? {
        for argument in node.arguments {
            guard argument.label?.text == "configuration" else {
                continue
            }
            return argument.expression.trimmedDescription
        }
        return nil
    }

    private static func previewArguments(in node: some FreestandingMacroExpansionSyntax) -> String {
        let arguments = node.arguments.compactMap { argument -> String? in
            if argument.label?.text == "configuration" || argument.label?.text == "content" {
                return nil
            }
            if argument.expression.is(ClosureExprSyntax.self) {
                return nil
            }

            if let label = argument.label?.text {
                return "\(label): \(argument.expression.trimmedDescription)"
            }

            return argument.expression.trimmedDescription
        }

        guard !arguments.isEmpty else {
            return ""
        }

        return "(\(arguments.joined(separator: ", ")))"
    }

    private static func hostArguments(
        titleExpression: String?,
        configurationExpression: String?
    ) -> String {
        switch (titleExpression, configurationExpression) {
        case (.some(let title), .some(let configuration)):
            "(\(title), configuration: \(configuration))"
        case (.some(let title), .none):
            "(\(title))"
        case (.none, .some(let configuration)):
            "(configuration: \(configuration))"
        case (.none, .none):
            ""
        }
    }

    private static func indent(_ source: String, by spaces: Int) -> String {
        let prefix = String(repeating: " ", count: spaces)
        return source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                line.isEmpty ? "" : prefix + line
            }
            .joined(separator: "\n")
    }

    private static func normalizedStatements(_ source: String) -> String {
        let lines = source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        guard lines.count > 1 else {
            return source
        }

        let commonIndent = lines
            .dropFirst()
            .filter { !$0.allSatisfy(\.isWhitespace) }
            .map(leadingSpaceCount)
            .min() ?? 0

        guard commonIndent > 0 else {
            return source
        }

        let normalizedLines = [lines[0]] + lines.dropFirst().map { line in
            removeLeadingSpaces(from: line, count: commonIndent)
        }
        return normalizedLines.joined(separator: "\n")
    }

    private static func leadingSpaceCount(_ line: String) -> Int {
        line.prefix { $0 == " " }.count
    }

    private static func removeLeadingSpaces(from line: String, count: Int) -> String {
        var index = line.startIndex
        var removed = 0
        while removed < count, index < line.endIndex, line[index] == " " {
            index = line.index(after: index)
            removed += 1
        }
        return String(line[index...])
    }
}

private struct HTMLPreviewDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(message: String) {
        self.message = message
        self.diagnosticID = MessageID(domain: "SwiftHTMLPreview.HTMLPreviewMacro", id: message)
        self.severity = .error
    }
}

private extension MacroExpansionContext {
    func diagnose(node: Syntax, message: String) {
        diagnose(Diagnostic(node: node, message: HTMLPreviewDiagnosticMessage(message: message)))
    }
}
