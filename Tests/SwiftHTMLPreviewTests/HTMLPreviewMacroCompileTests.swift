import SwiftHTMLPreview

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
