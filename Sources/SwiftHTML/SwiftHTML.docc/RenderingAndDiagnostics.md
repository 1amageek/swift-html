# Rendering And Diagnostics

Render HTML strings for static output, or render artifacts for diagnostics, hydration, diffing, and runtime integration.

## Renderer

``HTMLRenderer`` lowers the typed DSL into an internal graph and returns ``RenderArtifact``.

```swift
let renderer = HTMLRenderer()
let artifact = renderer.render(
    document {
        html {
            body {
                main {
                    h1("Dashboard")
                }
            }
        }
    }
)
```

The artifact contains:

| Field | Purpose |
|---|---|
| `html` | Serialized HTML output. |
| `hydration` | Component boundaries, state slots, server slots, and environment snapshots. |
| `clientHandlers` | Client event handlers captured during rendering. |
| `diagnostics` | Boundary and hydration diagnostics. |
| `domSnapshot()` | A read-only DOM snapshot for runtime or tests. |

## Render Options

Use ``HTMLRenderOptions`` to control render behavior.

```swift
let options = HTMLRenderOptions.development
    .withBrowserHydrationMarkers()
    .withClientHandlerClosures(true)

let artifact = AppView().renderArtifact(options: options)
```

| Option | Use |
|---|---|
| `recordsDiagnostics` | Collect render and hydration diagnostics. |
| `capturesClientHandlerClosures` | Keep closures in render artifacts for in-process runtimes and tests. |
| `emitsBrowserHydrationMarkers` | Emit HTML comments that mark component boundaries. |
| `componentEnvironmentOverrides` | Provide reconstructed environments for hydrated components. |

## Diagnostics

Diagnostics are reported in ``RenderArtifact/diagnostics``. Call ``RenderArtifact/validateHydration()`` when a clean hydration boundary is required.

```swift
let artifact = Page().renderArtifact()

do {
    try artifact.validateHydration()
} catch let error as RenderDiagnosticError {
    for diagnostic in error.diagnostics {
        print(diagnostic.formattedMessage)
    }
}
```

Diagnostics are data. A server framework can log them in development, fail tests, or convert them into application-specific errors.

## DOM Snapshots

Use ``RenderArtifact/domSnapshot()`` when a runtime or test needs a read-only view of the rendered DOM.

```swift
let snapshot = Page().renderArtifact().domSnapshot()
print(snapshot.html)
```

The snapshot API avoids exposing the mutable internal graph representation.

## Diffing

SwiftHTML computes patches between render artifacts:

```swift
let first = Page(count: 0).renderArtifact()
let second = Page(count: 1).renderArtifact()
let patches = HTMLDiffer().diff(from: first, to: second)
```

Patch records are suitable for browser command encoding, tests, or host-specific runtime adapters.
