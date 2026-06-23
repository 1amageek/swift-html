enum ASCIIStringUtilities {
    static func trimmedWhitespace(_ value: String) -> String {
        trimmedWhitespaceBytes(Array(value.utf8))
    }

    static func trimmedWhitespace(_ value: Substring) -> String {
        trimmedWhitespaceBytes(Array(value.utf8))
    }

    static func isAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (value >= 48 && value <= 57)
            || (value >= 65 && value <= 90)
            || (value >= 97 && value <= 122)
    }

    private static func trimmedWhitespaceBytes(_ bytes: [UInt8]) -> String {
        var start = 0
        var end = bytes.count
        while start < end, isWhitespace(bytes[start]) {
            start += 1
        }
        while end > start, isWhitespace(bytes[end - 1]) {
            end -= 1
        }
        return String(decoding: bytes[start..<end], as: UTF8.self)
    }

    private static func isWhitespace(_ byte: UInt8) -> Bool {
        byte == 32 || byte == 9 || byte == 10 || byte == 13 || byte == 12
    }
}
