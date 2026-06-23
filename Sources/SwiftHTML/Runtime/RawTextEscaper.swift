enum RawTextEscaper {
    static func escape(_ value: String, endTag: String) -> String {
        let bytes = Array(value.utf8)
        let needle = Array("</\(endTag)".utf8)
        guard !needle.isEmpty, bytes.count >= needle.count else {
            return value
        }

        let replacement = Array("<\\/\(endTag)".utf8)
        var output: [UInt8] = []
        output.reserveCapacity(bytes.count)

        var index = 0
        while index < bytes.count {
            if matches(bytes, at: index, needle: needle) {
                output.append(contentsOf: replacement)
                index += needle.count
            } else {
                output.append(bytes[index])
                index += 1
            }
        }

        return String(decoding: output, as: UTF8.self)
    }

    private static func matches(_ bytes: [UInt8], at index: Int, needle: [UInt8]) -> Bool {
        guard index + needle.count <= bytes.count else {
            return false
        }
        for offset in 0..<needle.count {
            if asciiLowercase(bytes[index + offset]) != asciiLowercase(needle[offset]) {
                return false
            }
        }
        return true
    }

    private static func asciiLowercase(_ byte: UInt8) -> UInt8 {
        if byte >= 65 && byte <= 90 {
            return byte + 32
        }
        return byte
    }
}
