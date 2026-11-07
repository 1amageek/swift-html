# SwiftHTML

## Purpose and Scope

This module owns the HTML graph/rendering state boundary, including `State`,
`Binding`, `StateRenderContext`, `StateStore`, and `RuntimeValueBox`.

Parent: [`../../DESIGN.md`](../../DESIGN.md). Children: none for this scoped
change. This module also owns mutation transaction capture and ordered hydration
updates; presentation policy remains downstream.

## Responsibilities and Boundaries

`StateStore` owns state-slot values, restored values, dirty-component
coalescing, and the invalidation callback. `RuntimeValueBox` owns the typed
erased `Sendable` value held by a slot. Rendering and event bindings use the
public store operations but do not access its storage directly.

The module does not own reconciliation scheduling, browser transport, timers,
or application state types. The invalidation owner receives a callback after
the store lock is released.

## Related Designs

| Design | Relationship | Contract Used | Summary | Cautions |
| --- | --- | --- | --- | --- |
| [`../../DESIGN.md`](../../DESIGN.md) | parent | package composition and public module boundary | Package-level ownership and child index | Keep module details here instead of duplicating them at package level |
| [`swift-web/Sources/SwiftWebBrowser/ClientRuntime/DESIGN.md`](https://github.com/1amageek/swift-web/blob/main/Sources/SwiftWebBrowser/ClientRuntime/DESIGN.md) | used by | rendered state and hydration records | SwiftWeb consumes state through RenderArtifact/hydration APIs | State slot identity and invalidation behavior are downstream compatibility contracts |

## Architecture

```text
State / Binding / event callback
              |
              v
          StateStore
              |
              +--> Mutex<Storage>
              |       +--> values / restoredValues
              |       +--> dirtyComponents
              |       +--> invalidationHandler
              |
              +--> callback after unlock --> reconciliation owner

RuntimeValueBox owns each type-erased Sendable slot value.
```

Generic input values are materialized into `RuntimeValueBox` before entering a
mutex closure. The closure only mutates or reads mutex-owned storage and never
borrows a generic caller value across the lock's deferred unlock path.

## Contracts and Invariants

- A component may supply `componentIdentity` for a stable client boundary across
  reflection-free SSR and browser builds. Native defaults retain the existing
  reflected identity. State declarations may supply `identity` for the slot's
  schema label; the actual typed value remains owned by the same StateStore.
- State source locations decode the authored StaticString on every target;
  Embedded does not collapse different source files into one placeholder.
- `ClientEnvironmentSnapshotValue.text` encodes one explicit public String as
  standard JSON without Foundation. Keys own stable names and opt into this
  factory; an unsupported generic Embedded value still throws. This supports
  Embedded SSR -> standard-WASM browser hydration, not generic Embedded
  Decodable restoration. Unsupported client-boundary metadata must prevent
  a runtime from being declared hydrated.

- StateStore captures resolved timing at each mutation, not event completion.
  A session renders consecutive equal-timing mutations together, retaining
  ordered groups with different timing, including no animation.
- Intermediate renders read immutable projections through the actual store.
  Bindings retain that store, never a temporary copy; shared storage is never
  rewound. Values and pending mutations are captured atomically, so later writes
  to existing slots cannot leak into a captured batch. Failed rendering retains
  pending mutations for retry. Projection storage is proportional to state slots.
- A reconciliation-scoped render-write overlay retains bookkeeping changes made
  while rendering between timing groups. Its Mutex-protected values are visible
  to subsequent reads and merged into the next projection, without admitting
  concurrent application writes. This prevents duplicate change observations.
- HydrationRuntimeUpdate.steps owns ordered batches and previous/next indexes.
  commandBatch remains the direct final-state diff for non-transaction consumers.
  A consumer applies steps or the final batch, never both.
- HTMLGraphBuilder.valueRevision compares Equatable and Sendable values by
  structural render identity. First render is revision zero; equal values keep
  it. This comparison memory is not hydrated app state, requires no Codable
  conformance, and is pruned when its scope disappears.
- The session owner serializes rendering. Work is one render per consecutive
  timing group, not per animation frame. Pending memory grows with unflushed
  mutations and is released after successful reconciliation.
- Event attributes retain the StateRenderContext that owns their captured
  handler. Hydration event ownership uses that declaration owner, not an
  incidental child-walk context. Attributes created outside a render context
  use the rendering-boundary owner. The mounted record establishes that validated
  owner during invocation, including attributes constructed before rendering.
- State context entry remains opaque to the fixed Embedded Release optimizer,
  preserving lexical ownership for property reads and captured Binding owners.
  The release fixture exercises property-wrapper reads/writes and ordered text
  patches, not only raw store writes.

- A slot is identified by its `StateSlotID`; storage replacement never changes
  that identity.
- `Optional.none` is a stored `Optional<String>` value, not an absent slot.
  The typed value may transition `nil -> value -> nil` without default or empty
  string substitution.
- A concurrent initial install has one winner under the mutex. A losing caller
  returns the already stored value for its requested type.
- `values`, `restoredValues`, and `dirtyComponents` share one
  `Synchronization.Mutex<Storage>` owner on Native, standard WASM, and Embedded
  WASM. Embedded conditions must not remove or weaken the isolation.
- A component is dirty at most once until explicitly cleared. The callback is
  captured under the mutex and invoked only after unlock.
- Snapshot entry references are retained under the mutex and serialized after
  unlock; this module change does not add whole-payload materialization.

## Runtime Flows

```text
read:  lock/find -> unlock -> decode/default -> lock/install winner -> unlock
write: box value -> lock/replace + coalesce dirty -> unlock -> notify
flush: snapshot mutations -> projected renders -> validate -> commit artifact
       -> consume captured prefix -> DOM owner applies ordered steps
```

## State, Ownership, and Lifecycle

`StateStore` owns its `Storage` for its lifetime. `RuntimeValueBox` owns the
type-erased value in each entry. The callback is supplied by the reconciliation
owner and detached with `setInvalidationHandler(nil)` during shutdown. No
pointer or borrowed view escapes a mutex closure.

| Logical state | Native storage/isolation | Standard WASM | Embedded WASM | Read / mutation / release |
|---|---|---|---|---|
| Slots, restoration, dirty membership | StateStore Mutex Storage | Same | Same | value/snapshot; set/restore/consume; store ARC lifetime |
| Pending transaction journal | Same Mutex Storage | Same | Same | pendingUpdate; set/consume; committed prefix released |
| Comparison memory | Same Mutex Storage | Same | Same | valueRevision; retain/restore comparisons; removed scopes pruned |
| Transaction timing | Transaction Mutex | Same | Same | animation getter/setter; scoped TaskLocal binding; lexical release |
| Render projection | Immutable TaskLocal snapshot | Same | Same | projected reads; no shared mutation; render scope release |
| Render bookkeeping overlay | RenderWrites Mutex dictionary | Same | Same | scoped read/record/consume; flush lifetime |

## Failure, Concurrency, and Constraints

Mutex closures do not perform I/O, await, rendering, or external callbacks.
Restore type mismatches and decode failures keep the existing diagnostic and
default-value behavior. The Embedded fix must not disable SIL verification,
introduce an unlocked state branch, or use `nonisolated(unsafe)` or
`@unchecked Sendable` as a workaround.

## Verification and Change Impact

| Contract | Evidence owner | Required evidence |
| --- | --- | --- |
| Optional value and dirty-cycle semantics | `SwiftHTMLStateHydrationTests` | `nil -> value -> nil`, one notification per dirty cycle, and typed reads |
| Concurrent install winner | `SwiftHTMLStateHydrationTests` | concurrent initial reads preserve one stored typed value |
| Common storage isolation | source review and target compilation | identical `Mutex<Storage>` declaration and access path on Native, standard WASM, and Embedded WASM |
| Embedded Debug compatibility | pinned Embedded fixture | former `Optional<String>` specialization builds in Debug and Release; runtime state path remains valid |

Changes to `StateStore`, `RuntimeValueBox`, or `SwiftHTMLMutex` require the
affected Native state suite and pinned standard/Embedded target gates.

Transaction tests own mixed animated/plain mutations, nested timing and nil,
throw restoration, projection ownership and comparison lifetime. The same Mutex
storage owns values, pending mutations and comparison entries on every target.
Comparisons, callbacks and rendering run outside its lock. There is no
target-specific Sendable or isolation exception.

### Projected state and event environments
An explicitly identified state declaration uses its component owner plus authored
identity as the storage key. Source file/line/column remain diagnostic metadata,
not its key; declaration expansion must preserve state across source projection.
Declarations without an identity retain the existing source-location contract.
The author owns unique, stable identity/schema names within each component and
changes the schema identity when its value meaning/type changes.
Captured client handlers retain the immutable environment active at creation,
and restore that environment and their state owner while invoking the callback.
A Task created by the callback inherits the same TaskLocal context. No callback
runs while a state-store mutex is held. Server-only environment values are not
serialized; client hydration still uses the explicit ClientEnvironmentRegistry.

### Client lifetime callbacks
HydrationRuntimeSession explicitly starts/ends its client lifetime. Appear and
disappear callbacks are keyed by their owner and structural render path, not
reused handler numbers or allocation-dependent node IDs. Starting/ending twice
is idempotent. A committed render compares old/new identities, invokes removed
callbacks in reverse order and added callbacks in render order after consuming
the prior mutation batch. Callback mutations remain pending for the next flush.
Rendering an SSR artifact alone never starts a client lifetime. The browser owner
starts it after actor startup and ends it before retiring the component.
