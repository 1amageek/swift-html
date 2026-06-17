import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftHTMLPreviewMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HTMLPreviewMacro.self,
    ]
}
