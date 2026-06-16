public enum HTMLDOMPatchError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingNode(HTMLNodeID)
    case childIndexOutOfBounds(parent: HTMLNodeID, index: Int)
    case childNodeMismatch(parent: HTMLNodeID, index: Int, expected: HTMLNodeID, actual: HTMLNodeID?)
    case keyedChildNotFound(parent: HTMLNodeID, key: Key)

    public var description: String {
        switch self {
        case .missingNode(let id):
            "Missing DOM node \(id.rawValue)"
        case .childIndexOutOfBounds(let parent, let index):
            "Child index \(index) is out of bounds for parent \(parent.rawValue)"
        case .childNodeMismatch(let parent, let index, let expected, let actual):
            "Child mismatch for parent \(parent.rawValue) at index \(index): expected \(expected.rawValue), actual \(actual?.rawValue.description ?? "nil")"
        case .keyedChildNotFound(let parent, let key):
            "Keyed child '\(key.rawValue)' was not found under parent \(parent.rawValue)"
        }
    }
}
