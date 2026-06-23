extension ClientEnvironmentRegistry {
    /// Every client-snapshot environment key that SwiftHTML itself can serialize.
    ///
    /// During server rendering, environment values whose key conforms to
    /// `ClientEnvironmentKey` are written into the client environment snapshot.
    /// The WASM runtime decodes that snapshot at hydration through a registry.
    /// A key that is missing from the registry makes
    /// `ClientEnvironmentRegistry.environment(from:)` throw `missingDecoder`,
    /// which aborts hydration and disables every interactive control on the page.
    ///
    /// This registry covers the framework-level keys (`locale`, `timeZone`,
    /// `calendar`, `colorScheme`, `layoutDirection`). Downstream modules that add
    /// their own `ClientEnvironmentKey`s should build their registry on top of
    /// this one with `.registering(_:)` so the framework keys stay decodable.
    public static let standard: ClientEnvironmentRegistry = {
        var registry = ClientEnvironmentRegistry()
        #if canImport(Foundation)
        registry = registry
            .registering(LocaleEnvironmentKey.self)
            .registering(TimeZoneEnvironmentKey.self)
            .registering(CalendarEnvironmentKey.self)
        #endif
        return registry
            .registering(ColorSchemeEnvironmentKey.self)
            .registering(LayoutDirectionEnvironmentKey.self)
    }()
}
