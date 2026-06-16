public enum ClientBundleLoadResolutionError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingBundle(ClientBundleID)
    case missingComponent(ComponentID)
    case cyclicBundleDependency([ClientBundleID])

    public var description: String {
        switch self {
        case .missingBundle(let id):
            "Missing client bundle '\(id.rawValue)'"
        case .missingComponent(let id):
            "Missing client component '\(id.rawValue)'"
        case .cyclicBundleDependency(let ids):
            "Cyclic client bundle dependency: \(ids.map(\.rawValue).joined(separator: " -> "))"
        }
    }
}
