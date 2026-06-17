public enum StateSnapshotError: Error, Sendable, Equatable, CustomStringConvertible {
    case encodingFailed(slotID: StateSlotID, valueType: String, message: String)

    public var description: String {
        switch self {
        case .encodingFailed(let slotID, let valueType, let message):
            "State snapshot encoding failed for \(slotID.rawValue) as \(valueType): \(message)"
        }
    }
}
