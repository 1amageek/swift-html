public protocol HTML: Sendable {
    /// The render walk's static dispatch point.
    ///
    /// Embedded Swift cannot downcast existentials, so each HTML kind
    /// (primitive, element, component) overrides this witness instead of
    /// being discovered with `as?` chains. The default handles values that
    /// are none of those kinds, matching the walk's historical fallback.
    static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID

    /// Type-erased render dispatch used by stable builder boundaries.
    func _buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID
}

extension HTML {
    public func _buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        Self._buildNode(self, in: &builder)
    }
}

/// HTML content that can be nested inside an element or document section.
///
/// A complete ``HTMLDocument`` deliberately does not conform to this protocol,
/// which prevents documents from being embedded inside component content.
public protocol Component: HTML {
    associatedtype Content: Component

    @ComponentBuilder
    var content: Content { get }

    // Render-walk hooks. These are requirements (not plain extension
    // members) so the ClientComponent/ServerComponent refinements override
    // them through the witness table: the walk asks these instead of
    // downcasting, which Embedded Swift does not support.
    static var _isClientComponent: Bool { get }
    static var _isServerComponent: Bool { get }
    var _clientLoadPolicy: LoadPolicy? { get }
    var _clientBundlePolicy: BundlePolicy? { get }
}

extension Component {
    public static var _isClientComponent: Bool { false }
    public static var _isServerComponent: Bool { false }
    public var _clientLoadPolicy: LoadPolicy? { nil }
    public var _clientBundlePolicy: BundlePolicy? { nil }

    public static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.buildComponentNode(html)
    }

}

extension Never: Component {
    public typealias Content = Never
}

public extension Component where Content == Never {
    /// Primitive components are rendered by their static lowering witness.
    ///
    /// The renderer must not evaluate this property.
    var content: Never {
        fatalError("Primitive components do not expose content.")
    }
}

protocol HTMLPrimitive: Component where Content == Never {
    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID
}

extension HTMLPrimitive {
    public static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        html.buildNode(in: &builder)
    }
}

public protocol ServerComponent: Component {}

extension ServerComponent {
    public static var _isServerComponent: Bool { true }
}

public protocol ClientComponent: Component, ClientLoadPolicyProviding, ClientBundlePolicyProviding {
    static var loadPolicy: LoadPolicy { get }
    static var bundle: BundlePolicy { get }
}

public extension ClientComponent {
    static var loadPolicy: LoadPolicy { .eager }
    static var bundle: BundlePolicy { .main }

    static var _isClientComponent: Bool { true }

    var clientLoadPolicy: LoadPolicy {
        Self.loadPolicy
    }

    var clientBundlePolicy: BundlePolicy {
        Self.bundle
    }

    var _clientLoadPolicy: LoadPolicy? {
        clientLoadPolicy
    }

    var _clientBundlePolicy: BundlePolicy? {
        clientBundlePolicy
    }
}

/// The stable lowering boundary produced by ``HTMLBuilder``.
///
/// Authoring APIs continue to return `some Component`; the builder erases the
/// concrete nested generic type at the property boundary so renderers do not
/// need to recover a large associated-type witness at runtime.
public struct ComponentContent: Component {
    public typealias Content = Never

    @usableFromInline
    let buildNodeClosure: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    @usableFromInline
    @_transparent
    init<Content: Component>(_ component: Content) {
        self.buildNodeClosure = { builder in
            Content._buildNode(component, in: &builder)
        }
    }

    init(tuple children: [ComponentContent]) {
        self.buildNodeClosure = { builder in
            var childIDs: [HTMLNodeID] = []
            childIDs.reserveCapacity(children.count)
            for (index, child) in children.enumerated() {
                childIDs.append(builder.withPathSegment("tuple:\(index)") { scopedBuilder in
                    child.buildNode(in: &scopedBuilder)
                })
            }
            return builder.addNode(kind: .fragment, children: childIDs)
        }
    }

    init(array children: [ComponentContent]) {
        self.buildNodeClosure = { builder in
            var childIDs: [HTMLNodeID] = []
            childIDs.reserveCapacity(children.count)
            for (index, child) in children.enumerated() {
                childIDs.append(builder.withPathSegment("array:\(index)") { scopedBuilder in
                    child.buildNode(in: &scopedBuilder)
                })
            }
            return builder.addNode(kind: .fragment, children: childIDs)
        }
    }

    init(optional child: ComponentContent?) {
        self.buildNodeClosure = { builder in
            guard let child else {
                return builder.addNode(kind: .fragment, children: [])
            }
            let childID = builder.withPathSegment("optional:some") { scopedBuilder in
                child.buildNode(in: &scopedBuilder)
            }
            return builder.addNode(kind: .fragment, children: [childID])
        }
    }

    init(conditional child: ComponentContent, branch: String) {
        self.buildNodeClosure = { builder in
            let childID = builder.withPathSegment("conditional:\(branch)") { scopedBuilder in
                child.buildNode(in: &scopedBuilder)
            }
            return builder.addNode(kind: .fragment, children: [childID])
        }
    }

    public static func _buildNode(
        _ html: ComponentContent,
        in builder: inout HTMLGraphBuilder
    ) -> HTMLNodeID {
        html.buildNode(in: &builder)
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        buildNodeClosure(&builder)
    }
}

typealias HTMLContent = ComponentContent

public struct EmptyHTML: HTMLPrimitive {
    public init() {}

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.addNode(kind: .fragment, children: [])
    }
}

public struct text: HTMLPrimitive, ExpressibleByStringLiteral {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(stringLiteral value: String) {
        self.value = value
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.addNode(kind: .text(builder.intern(value)), children: [])
    }
}

public struct rawHTML: HTMLPrimitive {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.addNode(kind: .rawHTML(builder.intern(value)), children: [])
    }
}
