public enum ClientBundleRuntimeStatus: String, Sendable, Codable, Equatable {
    case pending
    case loading
    case loaded
    case failed
}
