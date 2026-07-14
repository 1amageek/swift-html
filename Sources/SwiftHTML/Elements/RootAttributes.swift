/// Carrier for attributes that must land on the next element the graph walk
/// enters. Set by `RootAttributes`, consumed by `Element.buildNode` at
/// entry — the walk enters the subtree root before its children, so the
/// first entered element is the content's rendered root.
final class HTMLRootAttributeBox: Sendable {
    private struct State {
        var attributes: [HTMLAttribute]
        var consumed = false
    }

    private let state: SwiftHTMLMutex<State>

    init(attributes: [HTMLAttribute]) {
        state = SwiftHTMLMutex(State(attributes: attributes))
    }

    /// Hands out the attributes exactly once.
    func take() -> [HTMLAttribute]? {
        state.withLock { state in
            guard !state.consumed else {
                return nil
            }
            state.consumed = true
            return state.attributes
        }
    }

    var isConsumed: Bool {
        state.withLock { $0.consumed }
    }
}

/// Scope storage for the pending root-attribute box. Both the binding and
/// the consumption happen inside the render walk (a single synchronous
/// recursion on one thread), so unlike `HTMLAttributeTransformContext` no
/// enlarged-stack propagator is needed; Embedded, which has no `@TaskLocal`,
/// uses the same save/restore the transform context uses there.
enum HTMLRootAttributeContext {
    #if hasFeature(Embedded)
    nonisolated(unsafe) private static var pending: HTMLRootAttributeBox?

    static func withPending<Result>(
        _ box: HTMLRootAttributeBox,
        operation: () throws -> Result
    ) rethrows -> Result {
        let previous = pending
        pending = box
        defer { pending = previous }
        return try operation()
    }
    #else
    @TaskLocal private static var pending: HTMLRootAttributeBox?

    static func withPending<Result>(
        _ box: HTMLRootAttributeBox,
        operation: () throws -> Result
    ) rethrows -> Result {
        try $pending.withValue(box, operation: operation)
    }
    #endif

    static func consume() -> [HTMLAttribute] {
        pending?.take() ?? []
    }
}

/// Merges attributes into the root element rendered by `content` instead of
/// introducing a wrapper element. A wrapper changes the node tree and breaks
/// parent CSS contracts — grid/flex track children, direct-child and sibling
/// selectors — so attribute-only modifiers must leave the tree unchanged.
///
/// The content must render at least one element; rendering none is a
/// programming error and traps, so attributes are never silently dropped.
public struct RootAttributes<Content: HTML>: HTMLPrimitive {
    private let attributes: [HTMLAttribute]
    private let content: HTMLContent

    public init(_ attributes: [HTMLAttribute], @HTMLBuilder content: () -> Content) {
        self.attributes = attributes
        self.content = HTMLContent(content())
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        // Absorb an enclosing unconsumed scope so stacked attribute
        // modifiers all land on the same root element.
        let inherited = HTMLRootAttributeContext.consume()
        let box = HTMLRootAttributeBox(attributes: inherited + attributes)
        let node = HTMLRootAttributeContext.withPending(box) {
            builder.withPathSegment("root-attributes") { scopedBuilder in
                content.buildNode(in: &scopedBuilder)
            }
        }
        guard box.isConsumed else {
            fatalError("RootAttributes: the modified content rendered no element to carry the attributes.")
        }
        return node
    }
}
