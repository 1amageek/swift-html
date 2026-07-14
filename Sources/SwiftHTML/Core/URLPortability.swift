#if hasFeature(Embedded)
/// Minimal stand-ins for Foundation's URL family on Embedded Swift, covering
/// the surface SwiftWeb and its apps use to build hrefs: relative URLs with
/// paths and query items. Encoding matches Foundation's `urlPathAllowed` and
/// `urlQueryAllowed` sets so generated markup is identical across profiles.
public struct URL: Sendable, Hashable {
    public let absoluteString: String

    public init?(string: String) {
        guard !string.isEmpty else {
            return nil
        }
        self.absoluteString = string
    }

    public var relativeString: String {
        absoluteString
    }

    public var path: String {
        var remainder = absoluteString[...]
        if let schemeEnd = remainder.firstIndex(of: ":"),
           remainder[remainder.startIndex] != "/",
           !remainder[..<schemeEnd].contains("/") {
            remainder = remainder[remainder.index(after: schemeEnd)...]
            if remainder.hasPrefix("//") {
                remainder = remainder.dropFirst(2)
                if let pathStart = remainder.firstIndex(of: "/") {
                    remainder = remainder[pathStart...]
                } else {
                    return ""
                }
            }
        }
        if let queryStart = remainder.firstIndex(of: "?") {
            remainder = remainder[..<queryStart]
        }
        if let fragmentStart = remainder.firstIndex(of: "#") {
            remainder = remainder[..<fragmentStart]
        }
        return String(remainder)
    }
}

public struct URLQueryItem: Sendable, Hashable {
    public var name: String
    public var value: String?

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

public struct URLComponents: Sendable {
    public var path: String = ""
    public var queryItems: [URLQueryItem]?

    public init() {}

    public var url: URL? {
        var result = URLPercentEncoding.encode(path, allowed: URLPercentEncoding.pathAllowed)
        if let queryItems, !queryItems.isEmpty {
            result += "?"
            result += queryItems.map { item in
                let name = URLPercentEncoding.encode(item.name, allowed: URLPercentEncoding.queryAllowed)
                guard let value = item.value else {
                    return name
                }
                return name + "=" + URLPercentEncoding.encode(value, allowed: URLPercentEncoding.queryAllowed)
            }.joined(separator: "&")
        }
        return URL(string: result)
    }
}

enum URLPercentEncoding {
    // Foundation's CharacterSet.urlPathAllowed.
    static let pathAllowed = "!$&'()*+,-./:=@_~"
    // Foundation's CharacterSet.urlQueryAllowed, minus the pair separators
    // (&, =, +) inside item names/values, matching URLComponents' query-item
    // serialization.
    static let queryAllowed = "!$'()*,-./:;?@_~"

    static func encode(_ value: String, allowed: String) -> String {
        var result = ""
        result.reserveCapacity(value.utf8.count)
        let allowedBytes = Set(allowed.utf8)
        for byte in value.utf8 {
            let isUnreservedAlphanumeric =
                (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z"))
                || (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z"))
                || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9"))
            if isUnreservedAlphanumeric || allowedBytes.contains(byte) {
                result.append(Character(UnicodeScalar(byte)))
            } else {
                result.append("%")
                result.append(hexDigit(byte >> 4))
                result.append(hexDigit(byte & 0x0F))
            }
        }
        return result
    }

    private static func hexDigit(_ value: UInt8) -> Character {
        let digits = "0123456789ABCDEF"
        return Array(digits)[Int(value)]
    }
}
#endif
