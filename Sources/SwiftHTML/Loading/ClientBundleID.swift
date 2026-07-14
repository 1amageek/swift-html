public struct ClientBundleID: RawRepresentable, Sendable, Hashable, Comparable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: ClientBundleID, rhs: ClientBundleID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

#if !hasFeature(Embedded)
extension ClientBundleID: Codable {}
#endif
