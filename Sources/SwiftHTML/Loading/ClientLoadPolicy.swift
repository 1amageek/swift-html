public enum ClientLoadPolicy: String, Sendable, Comparable, CaseIterable {
    case eager
    case visible
    case interaction
    case idle
    case manual

    var priority: Int {
        switch self {
        case .eager:
            0
        case .visible:
            1
        case .interaction:
            2
        case .idle:
            3
        case .manual:
            4
        }
    }

    public static func < (lhs: ClientLoadPolicy, rhs: ClientLoadPolicy) -> Bool {
        lhs.priority < rhs.priority
    }
}

public typealias LoadPolicy = ClientLoadPolicy

#if !hasFeature(Embedded)
extension ClientLoadPolicy: Codable {}
#endif
