public enum BrowserHydrationNodeRole: String, Sendable, Codable, Equatable {
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
