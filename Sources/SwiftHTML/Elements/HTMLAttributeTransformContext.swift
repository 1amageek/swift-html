public protocol HTMLAttributeTransformer: Sendable {
    func transform(_ attributes: [HTMLAttribute]) -> [HTMLAttribute]
}

public enum HTMLAttributeTransformContext {
    @TaskLocal public static var transformer: (any HTMLAttributeTransformer)?

    public static func withValue<Result>(
        _ transformer: (any HTMLAttributeTransformer)?,
        operation: () throws -> Result
    ) rethrows -> Result {
        try EnlargedStackContext.withValue(HTMLAttributeTransformPropagator(transformer: transformer)) {
            try $transformer.withValue(transformer, operation: operation)
        }
    }

    public static func withValue<Result>(
        _ transformer: (any HTMLAttributeTransformer)?,
        operation: () async throws -> Result
    ) async rethrows -> Result {
        try await EnlargedStackContext.withValue(HTMLAttributeTransformPropagator(transformer: transformer)) {
            try await $transformer.withValue(transformer, operation: operation)
        }
    }

    static func transform(_ attributes: [HTMLAttribute]) -> [HTMLAttribute] {
        transformer?.transform(attributes) ?? attributes
    }
}

private struct HTMLAttributeTransformPropagator: EnlargedStackContextPropagator {
    let transformer: (any HTMLAttributeTransformer)?

    func apply<Result>(_ operation: () throws -> Result) rethrows -> Result {
        try HTMLAttributeTransformContext.$transformer.withValue(transformer, operation: operation)
    }
}
