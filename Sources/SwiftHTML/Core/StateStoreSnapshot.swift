public struct StateStoreSnapshot: Sendable, Codable, Equatable {
    public let schemaHash: String
    public let values: [String: StateSnapshotValue]

    public init(schemaHash: String, values: [String: StateSnapshotValue]) {
        self.schemaHash = schemaHash
        self.values = values
    }

    public static let empty = StateStoreSnapshot(schemaHash: "", values: [:])
}
