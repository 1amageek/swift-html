# State And Hydration

Use `ClientComponent` and `@State` to model browser-owned interaction state.

## Client State

``State`` stores component-scoped values in a ``StateStore`` during rendering and hydration.

```swift
struct Counter: ClientComponent, Sendable {
    @State private var count = 0

    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Count \(count)"
        }
    }
}
```

The component type and stable render path form the state identity. Use stable keys when rendering a reordering collection of stateful components.

```swift
ForEach(rows, id: { row in row.id }) { row in
    RowCounter(row: row)
}
```

## Bindings

``Binding`` connects form properties to state.

```swift
struct NameField: ClientComponent, Sendable {
    @State private var name = "Alice"

    var body: some HTML {
        input(
            .type(.text),
            .value($name),
            .onInput { event in
                name = event.value ?? ""
            }
        )
    }
}
```

Property bindings render the current value and are represented in runtime patch data.

## Hydration Manifests

Rendering a client component records hydration metadata.

```swift
let store = StateStore()
let artifact = Counter().renderArtifact(stateStore: store)

let components = artifact.hydration.components
let handlers = artifact.clientHandlers.handlers
```

The manifest includes component IDs, state slots, server slots, load policy, and client-safe environment snapshots.

## State Snapshots

``StateStore`` can export a ``StateStoreSnapshot`` for a runtime host. The snapshot is guarded by the rendered ``StateSchema`` hash, so a host can preserve state across HMR or component WASM replacement only when the state layout is compatible.

```swift
let store = StateStore()
let artifact = Counter().renderArtifact(stateStore: store)
let snapshot = try store.snapshot(schemaHash: artifact.hydration.stateSchemaHash)

let nextStore = StateStore()
nextStore.restore(snapshot)
```

The schema hash is derived from state slot identity, value type, and source location. Moving or changing a state property changes the schema and should remount that component instead of restoring stale state.

Only values that the runtime can encode are included in the snapshot. A state value that cannot be encoded falls back to the component initializer when restored.

## Runtime Dispatch

``BrowserHydrationRuntime`` provides a browser-neutral runtime wrapper. The host applies encoded command batches.

```swift
let host = BrowserDOMCommandBuffer()
var runtime = try BrowserHydrationRuntime(
    root: Counter(),
    host: host,
    stateStore: StateStore()
)

let handlerID = runtime.session.artifact.clientHandlers.handlers[0].id
let update = try runtime.invoke(handlerID: handlerID)

print(update.commands)
```

## Flush Semantics

``HydrationRuntimeSession/flush()`` tracks dirty components and preserves them across failed flushes. The current implementation re-renders the root and diffs the resulting artifact for correctness.

Scoped subtree rendering and scoped diffing are runtime optimizations. They are not required for the public SwiftHTML correctness contract.

## Transactions

``Transaction`` is a per-update context that travels from a state mutation to the
update it produces, mirroring SwiftUI's `Transaction`. It carries only a lowered
``TransactionAnimation`` (a CSS transition timing plus its duration), so the
reactivity layer stays unaware of how animations are described. A presentation
layer sets ``Transaction/current`` while an event handler runs; a DOM host that
mutates the live DOM reads it through ``BrowserDOMHost/apply(_:currentIndex:animation:)``
to interpolate that update's changes. SwiftHTML itself never reads it — it is a
side-channel for the runtime, kept off `StateStore` and `flush()` so those stay
animation-agnostic.

## Diagnostics

SwiftHTML reports boundary violations as diagnostics.

| Violation | Diagnostic behavior |
|---|---|
| Event handler outside a client-owned component | Reported during rendering. |
| `@State` outside a client-owned component | Reported during rendering. |
| Server-only environment read from a client-owned component | Reported during rendering. |
| Environment snapshot encoding failure | Reported during rendering. |

Use ``RenderArtifact/validateHydration()`` in tests or runtime entry points that require clean hydration.
