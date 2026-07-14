public enum BrowserHydrationNodeRole: String, Sendable, Equatable {
    case document
    case doctype
    case element
    case text
    case rawHTML
    case fragment
    case component
    case serverSlot
    case placeholder
    case comment
}

#if !hasFeature(Embedded)
extension BrowserHydrationNodeRole: Codable {}
#endif
