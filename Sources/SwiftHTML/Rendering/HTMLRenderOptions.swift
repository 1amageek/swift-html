public struct HTMLRenderOptions: Sendable {
    public let recordsDiagnostics: Bool
    public let capturesClientHandlerClosures: Bool
    public let emitsBrowserHydrationMarkers: Bool
    public let componentEnvironmentOverrides: [String: EnvironmentValues]

    public init(
        recordsDiagnostics: Bool = true,
        capturesClientHandlerClosures: Bool = true,
        emitsBrowserHydrationMarkers: Bool = false,
        componentEnvironmentOverrides: [String: EnvironmentValues] = [:]
    ) {
        self.recordsDiagnostics = recordsDiagnostics
        self.capturesClientHandlerClosures = capturesClientHandlerClosures
        self.emitsBrowserHydrationMarkers = emitsBrowserHydrationMarkers
        self.componentEnvironmentOverrides = componentEnvironmentOverrides
    }

    public static let development = HTMLRenderOptions()

    public static let production = HTMLRenderOptions(
        recordsDiagnostics: false,
        capturesClientHandlerClosures: false,
        emitsBrowserHydrationMarkers: false
    )

    public func withBrowserHydrationMarkers() -> HTMLRenderOptions {
        HTMLRenderOptions(
            recordsDiagnostics: recordsDiagnostics,
            capturesClientHandlerClosures: capturesClientHandlerClosures,
            emitsBrowserHydrationMarkers: true,
            componentEnvironmentOverrides: componentEnvironmentOverrides
        )
    }

    public func withClientHandlerClosures(_ capturesClientHandlerClosures: Bool) -> HTMLRenderOptions {
        HTMLRenderOptions(
            recordsDiagnostics: recordsDiagnostics,
            capturesClientHandlerClosures: capturesClientHandlerClosures,
            emitsBrowserHydrationMarkers: emitsBrowserHydrationMarkers,
            componentEnvironmentOverrides: componentEnvironmentOverrides
        )
    }

    public func withBrowserHydrationMarkers(_ emitsBrowserHydrationMarkers: Bool) -> HTMLRenderOptions {
        HTMLRenderOptions(
            recordsDiagnostics: recordsDiagnostics,
            capturesClientHandlerClosures: capturesClientHandlerClosures,
            emitsBrowserHydrationMarkers: emitsBrowserHydrationMarkers,
            componentEnvironmentOverrides: componentEnvironmentOverrides
        )
    }

    public func withComponentEnvironmentOverrides(
        _ componentEnvironmentOverrides: [String: EnvironmentValues]
    ) -> HTMLRenderOptions {
        HTMLRenderOptions(
            recordsDiagnostics: recordsDiagnostics,
            capturesClientHandlerClosures: capturesClientHandlerClosures,
            emitsBrowserHydrationMarkers: emitsBrowserHydrationMarkers,
            componentEnvironmentOverrides: componentEnvironmentOverrides
        )
    }
}
