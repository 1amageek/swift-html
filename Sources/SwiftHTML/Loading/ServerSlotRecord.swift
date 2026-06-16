public struct ServerSlotRecord: Sendable, Codable, Equatable {
    public let id: ServerSlotID
    public let ownerComponentID: ComponentID
    public let componentType: String
    public let path: String
    public let nodeID: HTMLNodeID

    public init(
        id: ServerSlotID,
        ownerComponentID: ComponentID,
        componentType: String,
        path: String,
        nodeID: HTMLNodeID
    ) {
        self.id = id
        self.ownerComponentID = ownerComponentID
        self.componentType = componentType
        self.path = path
        self.nodeID = nodeID
    }
}
