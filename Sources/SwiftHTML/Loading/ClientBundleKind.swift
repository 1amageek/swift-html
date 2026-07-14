public enum ClientBundleKind: String, Sendable {
    case runtime
    case route
    case shared
    case component
}

#if !hasFeature(Embedded)
extension ClientBundleKind: Codable {}
#endif
