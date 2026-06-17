public enum BundlePolicy: Sendable, Codable, Hashable {
    case main
    case component
    case named(String)
    case shared(String)
}
