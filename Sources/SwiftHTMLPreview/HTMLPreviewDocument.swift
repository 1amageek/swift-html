import SwiftHTML

struct HTMLPreviewDocument<Content: HTML>: Component {
    let titleText: String
    let configuration: HTMLPreviewConfiguration
    let content: Content

    init(
        title: String,
        configuration: HTMLPreviewConfiguration,
        content: Content
    ) {
        self.titleText = title
        self.configuration = configuration
        self.content = content
    }

    @HTMLBuilder
    var body: some HTML {
        document {
            html(.lang(configuration.language)) {
                head {
                    meta(.charset("utf-8"))
                    meta(.name("viewport"), .content("width=device-width, initial-scale=1"))
                    title {
                        titleText
                    }
                    style {
                        rawHTML(configuration.baseStyle)
                    }
                }
                SwiftHTML.body {
                    content
                }
            }
        }
    }
}
