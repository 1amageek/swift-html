public struct BrowserDOMCommandBatch: Sendable, Equatable {
    public let commands: [BrowserDOMCommand]

    public init(commands: [BrowserDOMCommand]) {
        self.commands = commands
    }

    public var isEmpty: Bool {
        commands.isEmpty
    }
}

#if !hasFeature(Embedded)
extension BrowserDOMCommandBatch: Codable {}
#endif
