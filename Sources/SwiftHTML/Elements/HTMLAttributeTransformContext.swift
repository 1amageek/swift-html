public protocol HTMLAttributeTransformer: Sendable {
    func transform(_ attributes: [HTMLAttribute]) -> [HTMLAttribute]
}

/// The active attribute transform for the render walk — atomic-CSS class
/// rewriting binds one around rendering.
///
/// The transform is stored as a closure, not an `any HTMLAttributeTransformer`:
/// Embedded Swift forbids non-class existentials, and a closure carries the
/// same capability on every profile. Propagation uses @TaskLocal where
/// available; Embedded has no @TaskLocal, and its render walk runs inline on
/// the single WASI thread, so a plain save/restore is equivalent there.
public enum HTMLAttributeTransformContext {
    public typealias Transform = @Sendable ([HTMLAttribute]) -> [HTMLAttribute]

    #if hasFeature(Embedded)
    nonisolated(unsafe) private static var current: Transform?

    public static func withTransform<Result>(
        _ transform: Transform?,
        operation: () throws -> Result
    ) rethrows -> Result {
        let previous = current
        current = transform
        defer { current = previous }
        return try operation()
    }

    public static func withTransform<Result>(
        _ transform: Transform?,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        let previous = current
        current = transform
        defer { current = previous }
        return try await operation()
    }
    #else
    @TaskLocal private static var current: Transform?

    public static func withTransform<Result>(
        _ transform: Transform?,
        operation: () throws -> Result
    ) rethrows -> Result {
        try EnlargedStackContext.withValue(HTMLAttributeTransformPropagator(transform: transform)) {
            try $current.withValue(transform, operation: operation)
        }
    }

    public static func withTransform<Result>(
        _ transform: Transform?,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        try await EnlargedStackContext.withValue(HTMLAttributeTransformPropagator(transform: transform)) {
            try await $current.withValue(transform, operation: operation)
        }
    }
    #endif


    /// Source-compatibility overloads for the pre-0.10 transformer-object API.
    /// Generic (`some`) rather than existential so they compile on Embedded.
    @available(*, deprecated, renamed: "withTransform")
    public static func withValue<Result>(
        _ transformer: some HTMLAttributeTransformer,
        operation: () throws -> Result
    ) rethrows -> Result {
        try withTransform({ transformer.transform($0) }, operation: operation)
    }

    @available(*, deprecated, renamed: "withTransform")
    public static func withValue<Result>(
        _ transformer: some HTMLAttributeTransformer,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        try await withTransform({ transformer.transform($0) }, operation: operation)
    }

    static func transform(_ attributes: [HTMLAttribute]) -> [HTMLAttribute] {
        current?(attributes) ?? attributes
    }
}

#if !hasFeature(Embedded)
private struct HTMLAttributeTransformPropagator: EnlargedStackContextPropagator {
    let transform: HTMLAttributeTransformContext.Transform?

    func apply<Result>(_ operation: () throws -> Result) rethrows -> Result {
        try HTMLAttributeTransformContext.withTransform(transform, operation: operation)
    }
}
#endif
