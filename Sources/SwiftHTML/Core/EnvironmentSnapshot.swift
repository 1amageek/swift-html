#if canImport(Foundation)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

public enum EnvironmentVisibility: Sendable, Equatable {
    case serverOnly
    case clientSnapshot
    case runtimeOnly
}

public struct ClientEnvironmentSnapshotValue: Sendable, Equatable {
    public let key: String
    public let valueType: String
    public let encoding: String
    public let encodedValue: String

    public init(key: String, valueType: String, encoding: String, encodedValue: String) {
        self.key = key
        self.valueType = valueType
        self.encoding = encoding
        self.encodedValue = encodedValue
    }
}

public struct ClientEnvironmentSnapshot: Sendable, Equatable {
    public let values: [ClientEnvironmentSnapshotValue]

    public init(values: [ClientEnvironmentSnapshotValue] = []) {
        self.values = values
    }

    public var schemaHash: String {
        stableSchemaHash(values.sorted { left, right in
            if left.key == right.key {
                return left.valueType < right.valueType
            }
            return left.key < right.key
        }
        .map { value in
            "\(value.key)|\(value.valueType)|\(value.encoding)"
        }
        .joined(separator: "\n"))
    }

    private func stableSchemaHash(_ value: String) -> String {
        StableHash.fnv1a64Hex(value)
    }
}

public enum ClientEnvironmentSnapshotError: Error, Sendable, CustomStringConvertible, Equatable {
    case encodingFailed(key: String, valueType: String, message: String)
    case unsupportedEncoding(key: String, encoding: String)
    case unavailableEncoding(key: String, valueType: String)
    case unavailableDecoding(key: String, valueType: String)
    case missingDecoder(key: String, valueType: String)
    case decodingFailed(key: String, valueType: String, message: String)

    public var description: String {
        switch self {
        case .encodingFailed(let key, let valueType, let message):
            "Client environment snapshot encoding failed for \(key) with value type \(valueType): \(message)"
        case .unsupportedEncoding(let key, let encoding):
            "Unsupported client environment snapshot encoding '\(encoding)' for \(key)"
        case .unavailableEncoding(let key, let valueType):
            "Client environment snapshot encoding is unavailable for \(key) with value type \(valueType) in this runtime"
        case .unavailableDecoding(let key, let valueType):
            "Client environment snapshot decoding is unavailable for \(key) with value type \(valueType) in this runtime"
        case .missingDecoder(let key, let valueType):
            "No client environment decoder was registered for \(key) with value type \(valueType)"
        case .decodingFailed(let key, let valueType, let message):
            "Client environment snapshot decoding failed for \(key) with value type \(valueType): \(message)"
        }
    }
}

public struct ClientEnvironmentSnapshotDecoder: Sendable {
    public let key: String
    public let valueType: String
    private let applyValue: @Sendable (ClientEnvironmentSnapshotValue, inout EnvironmentValues) throws -> Void

    public init<Key: ClientEnvironmentKey>(_ key: Key.Type) {
        self.key = Key.environmentKey
        self.valueType = RuntimeTypeName.reflecting(Key.Value.self)
        self.applyValue = { snapshotValue, environment in
            guard snapshotValue.encoding == "json" else {
                throw ClientEnvironmentSnapshotError.unsupportedEncoding(
                    key: snapshotValue.key,
                    encoding: snapshotValue.encoding
                )
            }

            do {
                #if canImport(Foundation)
                let data = Data(snapshotValue.encodedValue.utf8)
                environment[Key.self] = try JSONDecoder().decode(Key.Value.self, from: data)
                #else
                throw ClientEnvironmentSnapshotError.unavailableDecoding(
                    key: snapshotValue.key,
                    valueType: snapshotValue.valueType
                )
                #endif
            } catch let error as ClientEnvironmentSnapshotError {
                throw error
            } catch {
                throw ClientEnvironmentSnapshotError.decodingFailed(
                    key: snapshotValue.key,
                    valueType: snapshotValue.valueType,
                    message: RuntimeTypeName.errorDescription(error)
                )
            }
        }
    }

    func apply(_ value: ClientEnvironmentSnapshotValue, to environment: inout EnvironmentValues) throws {
        try applyValue(value, &environment)
    }
}

public struct ClientEnvironmentRegistry: Sendable {
    private let decoders: [String: ClientEnvironmentSnapshotDecoder]

    public init(decoders: [ClientEnvironmentSnapshotDecoder] = []) {
        var indexed: [String: ClientEnvironmentSnapshotDecoder] = [:]
        for decoder in decoders {
            indexed[Self.decoderKey(key: decoder.key, valueType: decoder.valueType)] = decoder
        }
        self.decoders = indexed
    }

    public static let empty = ClientEnvironmentRegistry()

    public func registering<Key: ClientEnvironmentKey>(_ key: Key.Type) -> ClientEnvironmentRegistry {
        var decoders = self.decoders
        let decoder = ClientEnvironmentSnapshotDecoder(key)
        decoders[Self.decoderKey(key: decoder.key, valueType: decoder.valueType)] = decoder
        return ClientEnvironmentRegistry(decoders: Array(decoders.values))
    }

    public func environment(
        from snapshot: ClientEnvironmentSnapshot,
        base: EnvironmentValues = EnvironmentValues()
    ) throws -> EnvironmentValues {
        var environment = base
        for value in snapshot.values {
            let decoderKey = Self.decoderKey(key: value.key, valueType: value.valueType)
            guard let decoder = decoders[decoderKey] else {
                throw ClientEnvironmentSnapshotError.missingDecoder(
                    key: value.key,
                    valueType: value.valueType
                )
            }
            try decoder.apply(value, to: &environment)
        }
        return environment
    }

    private static func decoderKey(key: String, valueType: String) -> String {
        "\(key)#\(valueType)"
    }
}

public struct EnvironmentReadRecord: Sendable, Equatable {
    public let key: String
    public let valueType: String
    public let visibility: EnvironmentVisibility

    public init(key: String, valueType: String, visibility: EnvironmentVisibility) {
        self.key = key
        self.valueType = valueType
        self.visibility = visibility
    }
}

final class EnvironmentReadRecorder: Sendable {
    private struct Storage: Sendable {
        var reads: [EnvironmentReadRecord] = []
        var snapshots: [String: ClientEnvironmentSnapshotValue] = [:]
        var snapshotErrors: [ClientEnvironmentSnapshotError] = []
    }

    private let storage = SwiftHTMLMutex(Storage())

    func record(
        _ read: EnvironmentReadRecord,
        snapshot: ClientEnvironmentSnapshotValue?,
        snapshotError: ClientEnvironmentSnapshotError? = nil
    ) {
        storage.withLock { storage in
            if !storage.reads.contains(read) {
                storage.reads.append(read)
            }

            if let snapshot {
                storage.snapshots[snapshot.key] = snapshot
            }

            if let snapshotError, !storage.snapshotErrors.contains(snapshotError) {
                storage.snapshotErrors.append(snapshotError)
            }
        }
    }

    func reads() -> [EnvironmentReadRecord] {
        storage.withLock { storage in
            storage.reads.sorted { left, right in
                left.key < right.key
            }
        }
    }

    func snapshot() -> ClientEnvironmentSnapshot {
        storage.withLock { storage in
            ClientEnvironmentSnapshot(values: storage.snapshots.values.sorted { left, right in
                left.key < right.key
            })
        }
    }

    func snapshotErrors() -> [ClientEnvironmentSnapshotError] {
        storage.withLock { storage in
            storage.snapshotErrors
        }
    }
}

enum EnvironmentReadContext {
    #if hasFeature(Embedded)
    nonisolated(unsafe) static var current: EnvironmentReadRecorder?

    static func withValue<Result>(
        _ value: EnvironmentReadRecorder?,
        operation: () throws -> Result
    ) rethrows -> Result {
        let previous = current
        current = value
        defer { current = previous }
        return try operation()
    }
    #else
    @TaskLocal static var current: EnvironmentReadRecorder?

    static func withValue<Result>(
        _ value: EnvironmentReadRecorder?,
        operation: () throws -> Result
    ) rethrows -> Result {
        try $current.withValue(value, operation: operation)
    }
    #endif
}

#if hasFeature(Embedded)
// Codable is unavailable in Embedded Swift; the client environment snapshot
// feeds hydration, which the embedded SSR profile does not serve, so the key
// protocol keeps its shape without the serialization requirement and
// snapshotting reports itself unavailable.
public protocol ClientEnvironmentKey: EnvironmentKey where Value: Sendable {}

public extension ClientEnvironmentKey {
    static var visibility: EnvironmentVisibility { .clientSnapshot }

    static func clientSnapshotValue(_ value: Value) throws -> ClientEnvironmentSnapshotValue? {
        throw ClientEnvironmentSnapshotError.unavailableEncoding(
            key: environmentKey,
            valueType: RuntimeTypeName.reflecting(Value.self)
        )
    }
}
#else
public protocol ClientEnvironmentKey: EnvironmentKey where Value: Codable & Sendable {}

public extension ClientEnvironmentKey {
    static var visibility: EnvironmentVisibility { .clientSnapshot }

    static func clientSnapshotValue(_ value: Value) throws -> ClientEnvironmentSnapshotValue? {
        #if canImport(Foundation)
        do {
            let data = try JSONEncoder().encode(value)
            guard let encodedValue = String(data: data, encoding: .utf8) else {
                throw ClientEnvironmentSnapshotError.encodingFailed(
                    key: environmentKey,
                    valueType: RuntimeTypeName.reflecting(Value.self),
                    message: "JSON encoder produced non-UTF-8 data."
                )
            }
            return ClientEnvironmentSnapshotValue(
                key: environmentKey,
                valueType: RuntimeTypeName.reflecting(Value.self),
                encoding: "json",
                encodedValue: encodedValue
            )
        } catch let error as ClientEnvironmentSnapshotError {
            throw error
        } catch {
            throw ClientEnvironmentSnapshotError.encodingFailed(
                key: environmentKey,
                valueType: RuntimeTypeName.reflecting(Value.self),
                message: RuntimeTypeName.errorDescription(error)
            )
        }
        #else
        throw ClientEnvironmentSnapshotError.unavailableEncoding(
            key: environmentKey,
            valueType: RuntimeTypeName.reflecting(Value.self)
        )
        #endif
    }
}
#endif

#if !hasFeature(Embedded)
extension ClientEnvironmentSnapshotValue: Codable {}
extension ClientEnvironmentSnapshot: Codable {}
#endif
