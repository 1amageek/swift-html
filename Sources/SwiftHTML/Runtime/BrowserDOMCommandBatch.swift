public struct BrowserDOMCommandBatch: Sendable, Equatable, Codable {
    public let commands: [BrowserDOMCommand]

    public init(commands: [BrowserDOMCommand]) {
        self.commands = commands
    }

    public var isEmpty: Bool {
        commands.isEmpty
    }
}
