public protocol ClientBundlePolicyProviding {
    var clientBundlePolicy: BundlePolicy { get }
}

public extension ClientBundlePolicyProviding {
    var clientBundlePolicy: BundlePolicy {
        .main
    }
}
