public struct ClientSymbolDependency: Sendable, Equatable {
    public let from: ClientSymbolID
    public let to: ClientSymbolID

    public init(from: ClientSymbolID, to: ClientSymbolID) {
        self.from = from
        self.to = to
    }
}

#if !hasFeature(Embedded)
extension ClientSymbolDependency: Codable {}
#endif
