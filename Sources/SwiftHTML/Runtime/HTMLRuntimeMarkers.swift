public enum HTMLRuntimeMarkers: Sendable {
    public enum BoundaryEdge: String, Sendable {
        case begin
        case end
    }

    public static let nodeAttribute = "data-node"
    public static let keyAttribute = "data-key"
    public static let eventAttributePrefix = "data-event-"
    public static let componentCommentPrefix = "component"
    public static let serverSlotCommentPrefix = "server-slot"

    public static func eventAttribute(_ eventName: String) -> String {
        "\(eventAttributePrefix)\(eventName)"
    }

    public static func componentCommentValue(
        _ componentID: ComponentID,
        edge: BoundaryEdge
    ) -> String {
        commentValue(prefix: componentCommentPrefix, id: componentID.rawValue, edge: edge)
    }

    public static func serverSlotCommentValue(
        _ serverSlotID: ServerSlotID,
        edge: BoundaryEdge
    ) -> String {
        commentValue(prefix: serverSlotCommentPrefix, id: serverSlotID.rawValue, edge: edge)
    }

    public static func componentCommentValue(
        rawID: String,
        edge: BoundaryEdge
    ) -> String {
        commentValue(prefix: componentCommentPrefix, id: rawID, edge: edge)
    }

    public static func serverSlotCommentValue(
        rawID: String,
        edge: BoundaryEdge
    ) -> String {
        commentValue(prefix: serverSlotCommentPrefix, id: rawID, edge: edge)
    }

    public static func commentValue(
        prefix: String,
        id: String,
        edge: BoundaryEdge
    ) -> String {
        "\(prefix):\(id):\(edge.rawValue)"
    }

    public static func comment(
        prefix: String,
        id: String,
        edge: BoundaryEdge
    ) -> String {
        "<!--\(commentValue(prefix: prefix, id: id, edge: edge))-->"
    }
}
