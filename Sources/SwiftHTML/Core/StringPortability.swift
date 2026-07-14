#if canImport(FoundationEssentials) || hasFeature(Embedded)
// FoundationEssentials hosts (WASM, slim Linux) lack NSString's string APIs,
// and Embedded Swift has neither Foundation nor _StringProcessing. These
// Foundation-free equivalents keep call sites identical across hosts; on
// Darwin, Foundation provides the real ones and this file compiles out.
extension String {
    public func replacingOccurrences(of target: String, with replacement: String) -> String {
        guard !target.isEmpty else {
            return self
        }
        let targetChars = Array(target)
        let chars = Array(self)
        var result = ""
        result.reserveCapacity(count)
        var index = 0
        scan: while index < chars.count {
            if index + targetChars.count <= chars.count {
                var offset = 0
                while offset < targetChars.count {
                    if chars[index + offset] != targetChars[offset] {
                        break
                    }
                    offset += 1
                }
                if offset == targetChars.count {
                    result += replacement
                    index += targetChars.count
                    continue scan
                }
            }
            result.append(chars[index])
            index += 1
        }
        return result
    }

    /// Substring containment without `_StringProcessing`, which Embedded
    /// Swift does not ship.
    public func containsSubstring(_ target: String) -> Bool {
        guard !target.isEmpty else {
            return true
        }
        let targetChars = Array(target)
        let chars = Array(self)
        guard targetChars.count <= chars.count else {
            return false
        }
        for start in 0...(chars.count - targetChars.count) {
            var offset = 0
            while offset < targetChars.count, chars[start + offset] == targetChars[offset] {
                offset += 1
            }
            if offset == targetChars.count {
                return true
            }
        }
        return false
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
    /// Portability twin of `firstRange(of:)`: plain forward scan, valid for
    /// `Substring` receivers (returned indices belong to the base string).
    public func firstRangeOfSubstring(_ target: String) -> Range<Self.Index>? {
        guard !target.isEmpty else {
            return nil
        }
        let targetChars = Array(target)
        var start = startIndex
        while start < endIndex {
            var cursor = start
            var matched = true
            for expected in targetChars {
                guard cursor < endIndex, self[cursor] == expected else {
                    matched = false
                    break
                }
                cursor = index(after: cursor)
            }
            if matched {
                return start..<cursor
            }
            start = index(after: start)
        }
        return nil
    }

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
#else
extension String {
    /// Mirror of the portability helper so call sites stay identical where
    /// Foundation provides the native APIs.
    public func containsSubstring(_ target: String) -> Bool {
        contains(target)
    }
}

extension StringProtocol {
    public func firstRangeOfSubstring(_ target: String) -> Range<Self.Index>? {
        firstRange(of: target)
    }
}
#endif
