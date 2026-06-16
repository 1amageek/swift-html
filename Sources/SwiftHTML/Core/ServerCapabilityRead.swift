import Synchronization

public struct ServerCapabilityReadRecord: Sendable, Equatable {
    public let key: String
    public let valueType: String

    public init(key: String, valueType: String) {
        self.key = key
        self.valueType = valueType
    }
}

public final class ServerCapabilityReadRecorder: Sendable {
    private let storage = Mutex([ServerCapabilityReadRecord]())

    public init() {}

    public func record(_ read: ServerCapabilityReadRecord) {
        storage.withLock { storage in
            if !storage.contains(read) {
                storage.append(read)
            }
        }
    }

    public func reads() -> [ServerCapabilityReadRecord] {
        storage.withLock { storage in
            storage.sorted { left, right in
                left.key < right.key
            }
        }
    }
}

public enum ServerCapabilityReadContext {
    @TaskLocal public static var current: ServerCapabilityReadRecorder?

    public static func record<Value>(
        _ key: String,
        valueType: Value.Type = Value.self
    ) {
        current?.record(ServerCapabilityReadRecord(
            key: key,
            valueType: String(reflecting: valueType)
        ))
    }
}
