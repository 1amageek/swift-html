public struct BrowserHydrationNodeRecord: Sendable, Equatable {
    public let id: HTMLNodeID
    public let parentID: HTMLNodeID?
    public let childIDs: [HTMLNodeID]
    public let role: BrowserHydrationNodeRole
    public let name: String?
    public let text: String?
    public let componentID: ComponentID?
    public let serverSlotID: ServerSlotID?
    public let attributes: [HTMLAttributeRecord]
    public let eventBindings: [BrowserHydrationEventBinding]
    public let key: Key?
    public let fingerprint: NodeFingerprint

    public init(
        id: HTMLNodeID,
        parentID: HTMLNodeID?,
        childIDs: [HTMLNodeID],
        role: BrowserHydrationNodeRole,
        name: String? = nil,
        text: String? = nil,
        componentID: ComponentID? = nil,
        serverSlotID: ServerSlotID? = nil,
        attributes: [HTMLAttributeRecord] = [],
        eventBindings: [BrowserHydrationEventBinding] = [],
        key: Key? = nil,
        fingerprint: NodeFingerprint
    ) {
        self.id = id
        self.parentID = parentID
        self.childIDs = childIDs
        self.role = role
        self.name = name
        self.text = text
        self.componentID = componentID
        self.serverSlotID = serverSlotID
        self.attributes = attributes
        self.eventBindings = eventBindings
        self.key = key
        self.fingerprint = fingerprint
    }
}

#if !hasFeature(Embedded)
extension BrowserHydrationNodeRecord: Codable {}
#endif
