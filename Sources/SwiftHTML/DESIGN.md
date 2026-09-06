# SwiftHTML

## Purpose and Scope

This module owns the HTML graph/rendering state boundary, including `State`,
`Binding`, `StateRenderContext`, `StateStore`, and `RuntimeValueBox`.

Parent: [`../../DESIGN.md`](../../DESIGN.md). Children: none for this scoped
change. The module design covers the StateStore path only; graph and renderer
contracts outside that path remain unchanged.

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
```

## State, Ownership, and Lifecycle

`StateStore` owns its `Storage` for its lifetime. `RuntimeValueBox` owns the
type-erased value in each entry. The callback is supplied by the reconciliation
owner and detached with `setInvalidationHandler(nil)` during shutdown. No
pointer or borrowed view escapes a mutex closure.

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
