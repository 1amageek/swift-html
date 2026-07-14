public protocol HTML: Sendable {
    /// The render walk's static dispatch point.
    ///
    /// Embedded Swift cannot downcast existentials, so each HTML kind
    /// (primitive, element, component) overrides this witness instead of
    /// being discovered with `as?` chains. The default handles values that
    /// are none of those kinds, matching the walk's historical fallback.
    static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID
}

extension HTML {
    public static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.buildFallbackNode()
    }
}

protocol HTMLPrimitive: HTML {
    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID
}

extension HTMLPrimitive {
    public static func _buildNode(_ html: Self, in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        html.buildNode(in: &builder)
    }
}

public protocol Component: HTML {
    associatedtype Body: HTML

    @HTMLBuilder
    var body: Body { get }

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

struct HTMLContent: Sendable {
    private let build: @Sendable (inout HTMLGraphBuilder) -> HTMLNodeID

    init<Content: HTML>(_ content: Content) {
        self.build = { builder in
            builder.append(content)
        }
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        build(&builder)
    }
}

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
