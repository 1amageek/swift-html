import Foundation

public struct StateSnapshotValue: Sendable, Codable, Equatable {
    public let valueType: String
    public let encoding: String
    public let encodedValue: String

    public init(valueType: String, encoding: String = "json", encodedValue: String) {
        self.valueType = valueType
        self.encoding = encoding
        self.encodedValue = encodedValue
    }

    public func decoded<Value: Decodable & Sendable>(
        as type: Value.Type = Value.self
    ) throws -> Value {
        guard encoding == "json" else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unsupported state snapshot encoding: \(encoding)"
                )
            )
        }
        let data = Data(encodedValue.utf8)
        return try JSONDecoder().decode(type, from: data)
    }
}
