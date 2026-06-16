public enum HydrationRuntimeError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingHandler(HandlerID)

    public var description: String {
        switch self {
        case .missingHandler(let id):
            "Hydration handler \(id.rawValue) was not found"
        }
    }
}
