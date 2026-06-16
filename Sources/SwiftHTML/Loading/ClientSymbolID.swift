public struct ClientSymbolID: RawRepresentable, Sendable, Hashable, Codable, Comparable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: ClientSymbolID, rhs: ClientSymbolID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
