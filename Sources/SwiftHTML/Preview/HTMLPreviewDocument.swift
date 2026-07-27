#if DEBUG && canImport(WebKit)
struct HTMLPreviewDocument<Content: Component>: HTMLDocument {
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

    var htmlAttributes: [HTMLAttribute] {
        [.lang(language)]
    }

    @HTMLBuilder
    var head: some Component {
        meta(.charset("utf-8"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1"))
        title {
            titleText
        }
        style {
            rawHTML(styleText)
        }
    }

    @HTMLBuilder
    var body: some Component {
        content
    }
}
#endif
