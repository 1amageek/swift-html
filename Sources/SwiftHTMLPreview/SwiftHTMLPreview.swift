@_exported import SwiftHTML
@_exported import SwiftUI

@freestanding(declaration)
public macro HTMLPreview<Content: HTML>(
    _ name: String? = nil,
    configuration: HTMLPreviewConfiguration = .default,
    @HTMLBuilder content: () -> Content
) = #externalMacro(module: "SwiftHTMLPreviewMacros", type: "HTMLPreviewMacro")

@freestanding(declaration)
public macro HTMLPreview<Content: HTML>(
    _ name: String? = nil,
    traits: PreviewTrait<Preview.ViewTraits>,
    _ additionalTraits: PreviewTrait<Preview.ViewTraits>...,
    configuration: HTMLPreviewConfiguration = .default,
    @HTMLBuilder content: () -> Content
) = #externalMacro(module: "SwiftHTMLPreviewMacros", type: "HTMLPreviewMacro")
