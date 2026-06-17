import SwiftHTMLPreview

#Preview("Compile") {
    HTMLPreview {
        div {
            "Preview"
        }
    }
}

#Preview("Fixed", traits: .fixedLayout(width: 390, height: 844)) {
    HTMLPreview {
        main {
            "Fixed viewport"
        }
    }
}

#Preview("Documentation Snippet", traits: .fixedLayout(width: 520, height: 360)) {
    HTMLPreview {
        main(.class("dashboard-shell")) {
            header(.class("dashboard-header")) {
                p(.class("eyebrow"), text: "SwiftHTML Preview")
                h1("Release Operations")
                p("Inspect layout, copy, and CSS directly in Xcode.")
            }

            section(.class("metric-grid"), .aria("label", "Release metrics")) {
                article(.class("metric-card")) {
                    p(.class("metric-label"), text: "Tests")
                    strong("108")
                    span(.class("metric-trend"), text: "passing")
                }

                article(.class("metric-card")) {
                    p(.class("metric-label"), text: "Preview")
                    strong("Ready")
                    span(.class("metric-trend"), text: "WebKit")
                }
            }
        }
    }
    .style {
        rule("body") {
            .margin("0")
            .padding("24px")
            .font("16px -apple-system, BlinkMacSystemFont, sans-serif")
        }

        rule(".dashboard-shell") {
            .display("grid")
            .gap("16px")
        }

        rule("h1, p") {
            .margin("0")
        }

        rule(".dashboard-header") {
            .display("grid")
            .gap("8px")
        }

        rule(".eyebrow, .metric-label, .metric-trend") {
            .color("color-mix(in srgb, CanvasText 68%, transparent)")
        }

        rule(".metric-grid") {
            .display("grid")
            .gridTemplateColumns("repeat(2, minmax(0, 1fr))")
            .gap("12px")
        }

        rule(".metric-card") {
            .display("grid")
            .gap("6px")
            .border("1px solid color-mix(in srgb, CanvasText 16%, transparent)")
            .borderRadius("8px")
            .padding("12px")
        }
    }
    .language("ja")
}
