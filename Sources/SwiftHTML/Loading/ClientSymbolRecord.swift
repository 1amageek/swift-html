public struct ClientSymbolRecord: Sendable, Codable, Equatable {
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
