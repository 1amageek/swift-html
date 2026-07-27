#if canImport(Foundation)
import Foundation

enum SwiftHTMLJSONDecoder {
    static func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data
    ) throws -> Value {
        let value = try JSONSerialization.jsonObject(
            with: data,
            options: [.fragmentsAllowed]
        )
        return try SwiftHTMLJSONValueDecoder(
            value: value,
            codingPath: []
        ).decode(type)
    }
}

private struct SwiftHTMLJSONValueDecoder: Decoder {
    let value: Any
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]

    func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        if type == Data.self {
            guard let string = value as? String,
                  let data = Data(base64Encoded: string),
                  let typedData = data as? Value else {
                throw typeMismatch(type, value: value, codingPath: codingPath)
            }
            return typedData
        }
        return try Value(from: self)
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        guard let object = value as? [String: Any] else {
            throw typeMismatch([String: Any].self, value: value, codingPath: codingPath)
        }
        return KeyedDecodingContainer(
            SwiftHTMLJSONKeyedDecodingContainer<Key>(
                object: object,
                codingPath: codingPath
            )
        )
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        guard let values = value as? [Any] else {
            throw typeMismatch([Any].self, value: value, codingPath: codingPath)
        }
        return SwiftHTMLJSONUnkeyedDecodingContainer(
            values: values,
            codingPath: codingPath
        )
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SwiftHTMLJSONSingleValueDecodingContainer(
            value: value,
            codingPath: codingPath
        )
    }
}

private struct SwiftHTMLJSONKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let object: [String: Any]
    let codingPath: [any CodingKey]

    var allKeys: [Key] {
        object.keys.compactMap(Key.init(stringValue:))
    }

    func contains(_ key: Key) -> Bool {
        object[key.stringValue] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let value = object[key.stringValue] else {
            throw keyNotFound(key, codingPath: codingPath)
        }
        return value is NSNull
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try singleValue(forKey: key).decode(type)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try singleValue(forKey: key).decode(type)
    }

    func decode<Value: Decodable>(
        _ type: Value.Type,
        forKey key: Key
    ) throws -> Value {
        let decoder = try nestedDecoder(forKey: key)
        return try decoder.decode(type)
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try nestedDecoder(forKey: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        try nestedDecoder(forKey: key).unkeyedContainer()
    }

    func superDecoder() throws -> any Decoder {
        let key = SwiftHTMLJSONKey(stringValue: "super")
        guard let value = object[key.stringValue] else {
            throw keyNotFound(key, codingPath: codingPath)
        }
        return SwiftHTMLJSONValueDecoder(
            value: value,
            codingPath: codingPath + [key]
        )
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        try nestedDecoder(forKey: key)
    }

    private func singleValue(
        forKey key: Key
    ) throws -> SwiftHTMLJSONSingleValueDecodingContainer {
        let decoder = try nestedDecoder(forKey: key)
        return SwiftHTMLJSONSingleValueDecodingContainer(
            value: decoder.value,
            codingPath: decoder.codingPath
        )
    }

    private func nestedDecoder(forKey key: Key) throws -> SwiftHTMLJSONValueDecoder {
        guard let value = object[key.stringValue] else {
            throw keyNotFound(key, codingPath: codingPath)
        }
        return SwiftHTMLJSONValueDecoder(
            value: value,
            codingPath: codingPath + [key]
        )
    }
}

private struct SwiftHTMLJSONUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let values: [Any]
    let codingPath: [any CodingKey]
    var currentIndex = 0

    var count: Int? { values.count }
    var isAtEnd: Bool { currentIndex >= values.count }

    mutating func decodeNil() throws -> Bool {
        let value = try nextValue()
        if value is NSNull {
            currentIndex += 1
            return true
        }
        return false
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: String.Type) throws -> String {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try nextSingleValue().decode(type)
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try nextSingleValue().decode(type)
    }

    mutating func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        let decoder = try nextDecoder()
        return try decoder.decode(type)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try nextDecoder().container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        try nextDecoder().unkeyedContainer()
    }

    mutating func superDecoder() throws -> any Decoder {
        try nextDecoder()
    }

    private mutating func nextSingleValue() throws -> SwiftHTMLJSONSingleValueDecodingContainer {
        let decoder = try nextDecoder()
        return SwiftHTMLJSONSingleValueDecodingContainer(
            value: decoder.value,
            codingPath: decoder.codingPath
        )
    }

    private mutating func nextDecoder() throws -> SwiftHTMLJSONValueDecoder {
        let index = currentIndex
        let value = try nextValue()
        currentIndex += 1
        return SwiftHTMLJSONValueDecoder(
            value: value,
            codingPath: codingPath + [SwiftHTMLJSONIndexKey(index: index)]
        )
    }

    private func nextValue() throws -> Any {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(
                Any.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Unkeyed JSON container is at end."
                )
            )
        }
        return values[currentIndex]
    }
}

private struct SwiftHTMLJSONSingleValueDecodingContainer: SingleValueDecodingContainer {
    let value: Any
    let codingPath: [any CodingKey]

    func decodeNil() -> Bool {
        value is NSNull
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        guard let number = value as? NSNumber, isJSONBoolean(number) else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return number.boolValue
    }

    func decode(_ type: String.Type) throws -> String {
        guard let string = value as? String else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return string
    }

    func decode(_ type: Double.Type) throws -> Double {
        let number = try jsonNumber(type)
        guard let result = Double(number.stringValue), result.isFinite else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return result
    }

    func decode(_ type: Float.Type) throws -> Float {
        let number = try jsonNumber(type)
        guard let result = Float(number.stringValue), result.isFinite else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return result
    }

    func decode(_ type: Int.Type) throws -> Int {
        try integer(type, transform: Int.init)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try integer(type, transform: Int8.init)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try integer(type, transform: Int16.init)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try integer(type, transform: Int32.init)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try integer(type, transform: Int64.init)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try integer(type, transform: UInt.init)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try integer(type, transform: UInt8.init)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try integer(type, transform: UInt16.init)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try integer(type, transform: UInt32.init)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try integer(type, transform: UInt64.init)
    }

    func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        try SwiftHTMLJSONValueDecoder(
            value: value,
            codingPath: codingPath
        ).decode(type)
    }

    private func jsonNumber<Value>(_ type: Value.Type) throws -> NSNumber {
        guard let number = value as? NSNumber, !isJSONBoolean(number) else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return number
    }

    private func integer<Value>(
        _ type: Value.Type,
        transform: (String) -> Value?
    ) throws -> Value {
        let number = try jsonNumber(type)
        guard let result = transform(number.stringValue) else {
            throw typeMismatch(type, value: value, codingPath: codingPath)
        }
        return result
    }
}

private struct SwiftHTMLJSONIndexKey: CodingKey {
    let intValue: Int?
    let stringValue: String

    init(index: Int) {
        self.intValue = index
        self.stringValue = "Index \(index)"
    }

    init?(intValue: Int) {
        self.init(index: intValue)
    }

    init?(stringValue: String) {
        return nil
    }
}

private struct SwiftHTMLJSONKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

private func isJSONBoolean(_ value: NSNumber) -> Bool {
    String(cString: value.objCType) == "c"
}

private func typeMismatch<Value>(
    _ type: Value.Type,
    value: Any,
    codingPath: [any CodingKey]
) -> DecodingError {
    DecodingError.typeMismatch(
        type,
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected \(type), found \(Swift.type(of: value))."
        )
    )
}

private func keyNotFound<Key: CodingKey>(
    _ key: Key,
    codingPath: [any CodingKey]
) -> DecodingError {
    DecodingError.keyNotFound(
        key,
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "No value is associated with key '\(key.stringValue)'."
        )
    )
}
#endif
