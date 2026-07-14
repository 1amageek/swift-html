public struct WasmAsset: Sendable, Equatable {
    public let path: String
    public let contentHash: String?
    public let byteSize: Int?

    public init(
        path: String,
        contentHash: String? = nil,
        byteSize: Int? = nil
    ) {
        self.path = path
        self.contentHash = contentHash
        self.byteSize = byteSize
    }
}

#if !hasFeature(Embedded)
extension WasmAsset: Codable {}
#endif
