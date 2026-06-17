import SwiftHTMLPreview

private struct CompilePreviewMetric: Sendable {
    let id: String
    let label: String
    let value: String
}

private struct CompilePreviewMetricsPanel: Component, Sendable {
    let title: String
    let metrics: [CompilePreviewMetric]

    var body: some HTML {
        section(.class("metrics-panel")) {
            h2(title)
            div(.class("metrics-grid")) {
                ForEach(metrics, id: \.id) { metric in
                    article(.class("metric")) {
                        p(.class("metric-label"), text: metric.label)
                        strong(metric.value)
                    }
                }
            }
        }
    }
}

#HTMLPreview("Compile") {
    div {
        "Macro"
    }
}

#HTMLPreview(
    "Fixed",
    configuration: HTMLPreviewConfiguration(viewport: .fixed(width: 390, height: 844))
) {
    main {
        "Fixed viewport"
    }
}

#HTMLPreview(
    "Traits",
    traits: .fixedLayout(width: 320, height: 240),
    configuration: HTMLPreviewConfiguration(language: "ja", viewport: .fixed(width: 320, height: 240))
) {
    section {
        "Trait viewport"
    }
}

#HTMLPreview(
    "Documentation Snippet",
    traits: .fixedLayout(width: 430, height: 360),
    configuration: HTMLPreviewConfiguration(
        baseStyle: """
        body {
          margin: 0;
          padding: 24px;
          font: 16px -apple-system, BlinkMacSystemFont, sans-serif;
        }
        .metrics-grid {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 12px;
        }
        .metric {
          border: 1px solid color-mix(in srgb, CanvasText 16%, transparent);
          border-radius: 8px;
          padding: 12px;
        }
        """,
        viewport: .fixed(width: 430, height: 360)
    )
) {
    CompilePreviewMetricsPanel(
        title: "Release Health",
        metrics: [
            CompilePreviewMetric(id: "tests", label: "Tests", value: "108 passing"),
            CompilePreviewMetric(id: "surface", label: "Surface", value: "HTML + CSS"),
            CompilePreviewMetric(id: "preview", label: "Preview", value: "#HTMLPreview"),
            CompilePreviewMetric(id: "runtime", label: "Runtime", value: "Hydration ready"),
        ]
    )
}
