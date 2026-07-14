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

    #if !hasFeature(Embedded)
    public init<Value: Sendable>(
        _ keyPath: WritableKeyPath<EnvironmentValues, Value> & Sendable,
        _ value: Value,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = { values in
            values[keyPath: keyPath] = value
        }
        self.content = content()
    }
    #endif

    /// Profile-neutral form backing `HTML.transformEnvironment(_:)`; key-path
    /// literals cannot compile under Embedded Swift.
    public init(
        transform: @escaping @Sendable (inout EnvironmentValues) -> Void,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = transform
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
