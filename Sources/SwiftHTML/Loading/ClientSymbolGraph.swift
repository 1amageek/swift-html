public struct ClientSymbolGraph: Sendable, Codable, Equatable {
    public let symbols: [ClientSymbolRecord]
    public let dependencies: [ClientSymbolDependency]
    public let components: [ClientComponentEntrypoint]
    public let runtimeSymbols: [ClientSymbolID]

    public init(
        symbols: [ClientSymbolRecord],
        dependencies: [ClientSymbolDependency] = [],
        components: [ClientComponentEntrypoint],
        runtimeSymbols: [ClientSymbolID] = []
    ) {
        self.symbols = symbols.sorted { left, right in
            left.id < right.id
        }
        self.dependencies = dependencies.sorted { left, right in
            if left.from == right.from {
                return left.to < right.to
            }
            return left.from < right.from
        }
        self.components = components.sorted { left, right in
            left.componentID.rawValue < right.componentID.rawValue
        }
        self.runtimeSymbols = runtimeSymbols.sorted()
    }
}
