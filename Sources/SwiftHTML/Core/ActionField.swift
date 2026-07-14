public struct ActionField: Sendable, Equatable {
    public let name: String
    public let value: String

    public init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }

    public init(_ name: String, _ value: Int) {
        self.init(name, String(value))
    }

    public init(_ name: String, _ value: Bool) {
        self.init(name, value ? "true" : "false")
    }
}

#if !hasFeature(Embedded)
extension ActionField: Codable {}
#endif
