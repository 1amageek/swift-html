import SwiftHTMLPreviewMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class HTMLPreviewMacroExpansionTests: XCTestCase {
    func testExpandsConfigurationIntoHostOnly() {
        assertMacroExpansion(
            """
            #HTMLPreview(
                "Fixed",
                configuration: HTMLPreviewConfiguration(language: "ja", viewport: .fixed(width: 390, height: 844))
            ) {
                main {
                    "Fixed viewport"
                }
            }
            """,
            expandedSource: """
            #Preview("Fixed") {
                SwiftHTMLPreview.HTMLPreviewHost("Fixed", configuration: HTMLPreviewConfiguration(language: "ja", viewport: .fixed(width: 390, height: 844))) {
                    main {
                        "Fixed viewport"
                    }
                }
            }
            """,
            macros: [
                "HTMLPreview": HTMLPreviewMacro.self,
            ]
        )
    }

    func testPassesPreviewTraitsThrough() {
        assertMacroExpansion(
            """
            #HTMLPreview(
                "Traits",
                traits: .fixedLayout(width: 320, height: 240),
                .sizeThatFitsLayout,
                configuration: HTMLPreviewConfiguration(language: "ja")
            ) {
                section {
                    "Trait viewport"
                }
            }
            """,
            expandedSource: """
            #Preview("Traits", traits: .fixedLayout(width: 320, height: 240), .sizeThatFitsLayout) {
                SwiftHTMLPreview.HTMLPreviewHost("Traits", configuration: HTMLPreviewConfiguration(language: "ja")) {
                    section {
                        "Trait viewport"
                    }
                }
            }
            """,
            macros: [
                "HTMLPreview": HTMLPreviewMacro.self,
            ]
        )
    }
}
