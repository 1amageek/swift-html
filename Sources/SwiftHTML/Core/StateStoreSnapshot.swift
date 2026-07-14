public struct StateStoreSnapshot: Sendable, Equatable {
    public let schemaHash: String
    public let values: [String: StateSnapshotValue]

    public init(schemaHash: String, values: [String: StateSnapshotValue]) {
        self.schemaHash = schemaHash
        self.values = values
    }

    public static let empty = StateStoreSnapshot(schemaHash: "", values: [:])
}

#if !hasFeature(Embedded)
extension StateStoreSnapshot: Codable {}
#endif
