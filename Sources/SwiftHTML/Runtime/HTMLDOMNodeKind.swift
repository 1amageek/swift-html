public enum HTMLDOMNodeKind: Sendable, Equatable {
    case document
    case doctype
    case element(String)
    case text(String)
    case rawHTML(String)
    case fragment
    case component(ComponentID)
    case serverSlot(ServerSlotID)
    case placeholder(String)
    case comment(String)
    case opaqueHTML(String)
}
