import SwiftHTML

struct HTMLPreviewDocument<Content: HTML>: Component {
    let titleText: String
    let styleText: String
    let language: String
    let content: Content

    init(
        title: String,
        style: String,
        language: String,
        content: Content
    ) {
        self.titleText = title
        self.styleText = style
        self.language = language
        self.content = content
    }

    @HTMLBuilder
    var body: some HTML {
        document {
            html(.lang(language)) {
                head {
                    meta(.charset("utf-8"))
                    meta(.name("viewport"), .content("width=device-width, initial-scale=1"))
                    title {
                        titleText
                    }
                    style {
                        rawHTML(styleText)
                    }
                }
                SwiftHTML.body {
                    content
                }
            }
        }
    }
}
