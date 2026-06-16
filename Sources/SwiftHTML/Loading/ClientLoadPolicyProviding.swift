public protocol ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy { get }
}

public extension ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy {
        .eager
    }
}
