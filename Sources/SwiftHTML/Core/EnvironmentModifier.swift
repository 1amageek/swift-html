public struct EnvironmentModifier<Content: HTML>: HTMLPrimitive {
    private let apply: @Sendable (inout EnvironmentValues) -> Void
    private let content: Content

    public init<Value: Sendable>(
        _ value: Value,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = { values in
            values[Value.self] = value
        }
        self.content = content()
    }

    public init<Key: EnvironmentKey>(
        _ key: Key.Type,
        value: Key.Value,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = { values in
            values[Key.self] = value
        }
        self.content = content()
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var scoped = builder.environment
        apply(&scoped)
        return builder.withEnvironment(scoped) { scopedBuilder in
            scopedBuilder.append(content)
        }
    }
}
