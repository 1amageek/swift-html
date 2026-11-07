public extension ClientEnvironmentSnapshotValue {
    /// Encodes an explicitly public text value with the standard JSON contract.
    static func text(key: String, value: String) -> Self {
        let digits = Array("0123456789abcdef".utf8)
        var encoded = "\""
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 34: encoded += "\\\""
            case 92: encoded += "\\\\"
            case 0...31:
                encoded += "\\u00"
                encoded.append(Character(Unicode.Scalar(digits[Int(scalar.value >> 4)])))
                encoded.append(Character(Unicode.Scalar(digits[Int(scalar.value & 15)])))
            default: encoded.unicodeScalars.append(scalar)
            }
        }
        encoded += "\""
        return Self(key: key, valueType: "Swift.String", encoding: "json", encodedValue: encoded)
    }
}
