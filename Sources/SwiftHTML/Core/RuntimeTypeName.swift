enum RuntimeTypeName {
    static func reflecting(_ type: Any.Type) -> String {
        #if hasFeature(Embedded)
        "EmbeddedType"
        #else
        String(reflecting: type)
        #endif
    }

    static func describing<Value>(_ value: Value) -> String {
        #if hasFeature(Embedded)
        if let string = value as? String {
            return string
        }
        if let int = value as? Int {
            return String(int)
        }
        if let uint = value as? UInt {
            return String(uint)
        }
        return "embedded"
        #else
        String(describing: value)
        #endif
    }

    static func sourceFileID(_ fileID: StaticString) -> String {
        #if hasFeature(Embedded)
        "embedded"
        #else
        String(describing: fileID)
        #endif
    }

    static func errorDescription(_ error: any Error) -> String {
        #if hasFeature(Embedded)
        "error"
        #else
        String(describing: error)
        #endif
    }
}
