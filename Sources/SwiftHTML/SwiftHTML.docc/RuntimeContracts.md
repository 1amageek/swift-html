# Runtime Contracts

SwiftHTML defines runtime data structures without binding to a specific browser implementation.

## Browser Host

``BrowserDOMHost`` is the boundary between SwiftHTML command batches and a concrete DOM adapter.

```swift
struct LoggingHost: BrowserDOMHost {
    func apply(
        _ batch: BrowserDOMCommandBatch,
        updatedIndex: BrowserHydrationIndex
    ) throws {
        for command in batch.commands {
            print(command)
        }
    }
}
```

A JavaScriptKit-backed package can implement this protocol. A server-side test can use ``BrowserDOMCommandBuffer``.

## Command Batches

``BrowserDOMCommandEncoder`` converts patches into browser commands:

```swift
let oldArtifact = Page(count: 0).renderArtifact()
let newArtifact = Page(count: 1).renderArtifact()
let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

let batch = BrowserDOMCommandEncoder().encode(patches)
```

The batch is `Codable`, which keeps the runtime contract transport-neutral.

## Hydration Index

``BrowserHydrationIndex`` maps rendered nodes, components, server slots, and handlers into runtime records.

```swift
let artifact = Page().renderArtifact()
let index = artifact.browserHydrationIndex()

print(index.nodes)
print(index.components)
print(index.handlers)
```

The index is the public runtime facade. It avoids exposing SwiftHTML's internal graph representation.

## Split Loading

SwiftHTML includes split-loading contracts for runtime packages.

```swift
let planner = ClientBundlePlanner()
let manifest = planner.plan(symbolGraph)
```

The planner operates on symbol and component metadata. It does not build WASM, serve assets, or import JavaScript.

| Type | Purpose |
|---|---|
| ``ClientSymbolGraph`` | Build-time symbol dependency graph. |
| ``ClientBundlePlanner`` | Produces bundle records and component asset records. |
| ``ClientBundleManifest`` | Describes runtime, shared, route, and component bundles. |
| ``ClientBundleLoadResolver`` | Resolves a load plan from a manifest and policy. |
| ``ClientBundleLoadingRuntime`` | Tracks loading state. |

## Runtime Ownership

SwiftHTML owns the data model. A runtime package owns:

- WASM module loading.
- JavaScriptKit imports.
- DOM API calls.
- URL query decoding.
- Host script injection.
- Asset serving and cache policy.
