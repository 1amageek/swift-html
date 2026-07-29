public struct EnvironmentModifier<Content: Component>: HTMLPrimitive {
    private let apply: @Sendable (inout EnvironmentValues) -> Void
    // Erase the builder result at storage so Standard WASM does not need to
    // complete generic field metadata while lowering the environment scope.
    private let content: ComponentContent

    public init<Value: Sendable>(
        _ value: Value,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = { values in
            values[Value.self] = value
        }
        self.content = ComponentContent(content())
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
        self.content = ComponentContent(content())
    }
    #endif

    /// Profile-neutral form backing `HTML.transformEnvironment(_:)`; key-path
    /// literals cannot compile under Embedded Swift.
    public init(
        transform: @escaping @Sendable (inout EnvironmentValues) -> Void,
        @HTMLBuilder content: () -> Content
    ) {
        self.apply = transform
        self.content = ComponentContent(content())
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var scoped = builder.environment
        apply(&scoped)
        return builder.withEnvironment(scoped) { scopedBuilder in
            scopedBuilder.append(content)
        }
    }
}
