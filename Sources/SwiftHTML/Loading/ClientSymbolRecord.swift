public struct ClientSymbolRecord: Sendable, Equatable {
    public let id: ClientSymbolID
    public let estimatedByteSize: Int

    public init(
        id: ClientSymbolID,
        estimatedByteSize: Int = 0
    ) {
        self.id = id
        self.estimatedByteSize = estimatedByteSize
    }
}

#if !hasFeature(Embedded)
extension ClientSymbolRecord: Codable {}
#endif
