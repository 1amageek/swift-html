public struct HTMLPreviewViewport: Sendable, Equatable {
    public var width: Double?
    public var height: Double?

    public init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }

    public static let responsive = HTMLPreviewViewport()

    public static func fixed(width: Double, height: Double) -> HTMLPreviewViewport {
        HTMLPreviewViewport(width: width, height: height)
    }
}
