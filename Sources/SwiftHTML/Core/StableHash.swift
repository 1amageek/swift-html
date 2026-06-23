enum StableHash {
    static func fnv1a64Hex(_ value: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hex(hash)
    }

    private static func hex(_ value: UInt64) -> String {
        let raw = String(value, radix: 16, uppercase: false)
        if raw.count >= 16 {
            return raw
        }
        return String(repeating: "0", count: 16 - raw.count) + raw
    }
}
