#if canImport(Foundation)
import Foundation
#endif

struct RuntimeValueBox: Sendable {
    private let storedValue: any Sendable

    init<Value: Sendable>(_ value: Value) {
        self.storedValue = value
    }

    func value<Value: Sendable>(as type: Value.Type = Value.self) -> Value? {
        storedValue as? Value
    }

    func snapshotValue(valueType: String) throws -> StateSnapshotValue {
        #if canImport(Foundation)
        guard let codable = storedValue as? any Codable else {
            throw RuntimeValueBoxSnapshotError.notCodable
        }

        let data = try JSONEncoder().encode(AnyEncodable(codable))
        guard let encodedValue = String(data: data, encoding: .utf8) else {
            throw RuntimeValueBoxSnapshotError.invalidUTF8
        }
        return StateSnapshotValue(valueType: valueType, encodedValue: encodedValue)
        #else
        throw RuntimeValueBoxSnapshotError.unavailable
        #endif
    }
}

private enum RuntimeValueBoxSnapshotError: Error, CustomStringConvertible {
    case notCodable
    case invalidUTF8
    case unavailable

    var description: String {
        switch self {
        case .notCodable:
            "State snapshot values must conform to Codable."
        case .invalidUTF8:
            "State snapshot encoding produced invalid UTF-8."
        case .unavailable:
            "State snapshot encoding is unavailable in this runtime."
        }
    }
}

#if canImport(Foundation)
private struct AnyEncodable: Encodable {
    private let encodeValue: (any Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encodeValue = value.encode
    }

    func encode(to encoder: any Encoder) throws {
        try encodeValue(encoder)
    }
}
#endif
