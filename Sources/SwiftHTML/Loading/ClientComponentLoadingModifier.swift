public struct ClientComponentLoadingOverride<Content: HTML>: HTMLPrimitive {
    public let content: Content
    public let loadPolicy: LoadPolicy?
    public let bundle: BundlePolicy?

    public init(
        content: Content,
        loadPolicy: LoadPolicy? = nil,
        bundle: BundlePolicy? = nil
    ) {
        self.content = content
        self.loadPolicy = loadPolicy
        self.bundle = bundle
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        builder.withClientLoadingOverride(
            ClientLoadingContractOverride(
                loadPolicy: loadPolicy,
                bundle: bundle
            )
        ) { builder in
            builder.append(content)
        }
    }
}

public extension HTML {
    func loadPolicy(_ policy: LoadPolicy) -> ClientComponentLoadingOverride<Self> {
        ClientComponentLoadingOverride(content: self, loadPolicy: policy)
    }

    func bundle(_ policy: BundlePolicy) -> ClientComponentLoadingOverride<Self> {
        ClientComponentLoadingOverride(content: self, bundle: policy)
    }
}

struct ClientLoadingContractOverride: Sendable, Equatable {
    var loadPolicy: LoadPolicy?
    var bundle: BundlePolicy?

    static let empty = ClientLoadingContractOverride()

    init(
        loadPolicy: LoadPolicy? = nil,
        bundle: BundlePolicy? = nil
    ) {
        self.loadPolicy = loadPolicy
        self.bundle = bundle
    }

    func merged(with other: ClientLoadingContractOverride) -> ClientLoadingContractOverride {
        ClientLoadingContractOverride(
            loadPolicy: other.loadPolicy ?? loadPolicy,
            bundle: other.bundle ?? bundle
        )
    }

    var isEmpty: Bool {
        loadPolicy == nil && bundle == nil
    }
}
