#if canImport(Foundation)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

public struct StateSnapshotValue: Sendable, Equatable {
    public let valueType: String
    public let encoding: String
    public let encodedValue: String

    public init(valueType: String, encoding: String = "json", encodedValue: String) {
        self.valueType = valueType
        self.encoding = encoding
        self.encodedValue = encodedValue
    }

    #if !hasFeature(Embedded)
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
        #if canImport(Foundation)
        let data = Data(encodedValue.utf8)
        return try JSONDecoder().decode(type, from: data)
        #else
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "State snapshot decoding is unavailable in this runtime."
            )
        )
        #endif
    }
    #endif
}

#if !hasFeature(Embedded)
extension StateSnapshotValue: Codable {}
#endif
