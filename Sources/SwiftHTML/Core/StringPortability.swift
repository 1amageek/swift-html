#if canImport(FoundationEssentials)
// FoundationEssentials hosts (WASM, slim Linux) lack NSString's string
// APIs. These Foundation-free equivalents keep call sites identical across
// hosts; on Darwin, Foundation provides the real ones and this file
// compiles out.
extension String {
    public func replacingOccurrences(of target: String, with replacement: String) -> String {
        guard !target.isEmpty else {
            return self
        }
        var result = ""
        result.reserveCapacity(count)
        var remainder = self[...]
        while let range = remainder.firstRange(of: target) {
            result += remainder[..<range.lowerBound]
            result += replacement
            remainder = remainder[range.upperBound...]
        }
        result += remainder
        return result
    }
}

/// Minimal stand-in for Foundation's `CharacterSet` on FoundationEssentials
/// hosts, covering the sets SwiftWeb trims with.
public struct CharacterSet: Sendable {
    let containsScalar: @Sendable (Unicode.Scalar) -> Bool

    public static let whitespacesAndNewlines = CharacterSet { scalar in
        scalar.properties.isWhitespace
    }

    public static let whitespaces = CharacterSet { scalar in
        scalar == " " || scalar == "\t"
    }
}

extension StringProtocol {
    public func trimmingCharacters(in set: CharacterSet) -> String {
        var view = self[...]
        while let first = view.unicodeScalars.first, set.containsScalar(first) {
            view = view.dropFirst()
        }
        while let last = view.unicodeScalars.last, set.containsScalar(last) {
            view = view.dropLast()
        }
        return String(view)
    }
}
#endif
