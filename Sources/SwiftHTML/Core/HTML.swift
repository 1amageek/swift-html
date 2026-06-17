public protocol HTML {}

protocol HTMLPrimitive: HTML {
    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID
}

public protocol Component: HTML {
    associatedtype Body: HTML

    @HTMLBuilder
    var body: Body { get }
}

public protocol ServerComponent: Component {}

public protocol ClientComponent: Component, ClientLoadPolicyProviding, ClientBundlePolicyProviding {
    static var loadPolicy: LoadPolicy { get }
    static var bundle: BundlePolicy { get }
}

public extension ClientComponent {
    static var loadPolicy: LoadPolicy { .eager }
    static var bundle: BundlePolicy { .main }

    var clientLoadPolicy: LoadPolicy {
        Self.loadPolicy
    }

    var clientBundlePolicy: BundlePolicy {
        Self.bundle
    }
}

struct HTMLContent {
    private let build: (inout HTMLGraphBuilder) -> HTMLNodeID

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
