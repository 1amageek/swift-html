public enum BundlePolicy: Sendable, Hashable {
    case main
    case component
    case named(String)
    case shared(String)
}

#if !hasFeature(Embedded)
extension BundlePolicy: Codable {}
#endif
