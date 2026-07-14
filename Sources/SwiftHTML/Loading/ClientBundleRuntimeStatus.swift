public enum ClientBundleRuntimeStatus: String, Sendable, Equatable {
    case pending
    case loading
    case loaded
    case failed
}

#if !hasFeature(Embedded)
extension ClientBundleRuntimeStatus: Codable {}
#endif
