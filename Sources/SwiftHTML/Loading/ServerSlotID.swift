public struct ServerSlotID: RawRepresentable, Sendable, Hashable, Codable, Comparable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: ServerSlotID, rhs: ServerSlotID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
