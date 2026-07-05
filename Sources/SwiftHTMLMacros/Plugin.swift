import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftHTMLMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HTMLPreviewMacro.self,
    ]
}
