public struct BrowserHydrationEventBinding: Sendable, Codable, Equatable {
    public let nodeID: HTMLNodeID
    public let handlerID: HandlerID
    public let eventName: String
    public let componentID: ComponentID?

    public init(
        nodeID: HTMLNodeID,
        handlerID: HandlerID,
        eventName: String,
        componentID: ComponentID?
    ) {
        self.nodeID = nodeID
        self.handlerID = handlerID
        self.eventName = eventName
        self.componentID = componentID
    }
}
