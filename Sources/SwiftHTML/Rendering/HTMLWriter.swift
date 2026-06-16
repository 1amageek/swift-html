public struct HTMLWriter: Sendable {
    private var storage: String

    public init(minimumCapacity: Int = 0) {
        self.storage = ""
        self.storage.reserveCapacity(minimumCapacity)
    }

    public var output: String {
        storage
    }

    public mutating func write(_ value: String) {
        storage.append(contentsOf: value)
    }

    public mutating func writeEscapedText(_ value: String) {
        storage.append(contentsOf: Self.escapeText(value))
    }

    public mutating func writeEscapedAttribute(_ value: String) {
        storage.append(contentsOf: Self.escapeAttribute(value))
    }

    public static func escapeText(_ value: String) -> String {
        var output = ""
        output.reserveCapacity(value.count)
        for character in value {
            switch character {
            case "&":
                output.append(contentsOf: "&amp;")
            case "<":
                output.append(contentsOf: "&lt;")
            case ">":
                output.append(contentsOf: "&gt;")
            default:
                output.append(character)
            }
        }
        return output
    }

    public static func escapeAttribute(_ value: String) -> String {
        var output = ""
        output.reserveCapacity(value.count)
        for character in value {
            switch character {
            case "&":
                output.append(contentsOf: "&amp;")
            case "<":
                output.append(contentsOf: "&lt;")
            case ">":
                output.append(contentsOf: "&gt;")
            case "\"":
                output.append(contentsOf: "&quot;")
            case "'":
                output.append(contentsOf: "&#39;")
            default:
                output.append(character)
            }
        }
        return output
    }
}
