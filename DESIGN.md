# swift-html

## Purpose and Scope

This package owns SwiftHTML's server-side graph, state, rendering, hydration,
and browser-runtime support. This document is the package design authority and
indexes the module designs used by its SwiftPM targets.

Parent: none; this repository is an independently maintained Swift package.
Children: SwiftHTML, SwiftHTMLClientRuntime, SwiftHTMLPreview, and
SwiftHTMLMacros. The StateStore contract is owned by
[`Sources/SwiftHTML/DESIGN.md`](Sources/SwiftHTML/DESIGN.md).

## Responsibilities and Boundaries

The package owns the composition and public boundaries between graph building,
rendering, state, hydration, and browser-runtime modules. Module-level state
and ownership contracts remain in their module design authorities.

## Related Designs

| Design | Relationship | Contract Used | Summary | Cautions |
| --- | --- | --- | --- | --- |
| [`swift-web/DESIGN.md`](https://github.com/1amageek/swift-web/blob/main/DESIGN.md) | used by | SwiftHTML public rendering and hydration APIs | SwiftWeb consumes this package | Changes to state-slot identity or invalidation require downstream hydration verification |
| [`Sources/SwiftHTML/DESIGN.md`](Sources/SwiftHTML/DESIGN.md) | child | StateStore and RuntimeValueBox contracts | Owns the state path changed in this task | Re-run the module's target-specific verification when its storage path changes |
| `Package.swift` | package build authority | Swift 6.4 and Embedded target settings | Selects the pinned toolchain and target-specific compilation mode | Embedded validation must use the matching `_wasm-embedded` SDK |

## Architecture

```text
SwiftHTML package
    +--> SwiftHTML ------------> graph, rendering, state, hydration
    +--> SwiftHTMLClientRuntime -> browser DOM/runtime bridge
    +--> SwiftHTMLPreview ------> host preview support
    +--> SwiftHTMLMacros -------> host build-time macros
```

## Contracts and Invariants

Package composition must preserve each child module's public contract and
must not move state ownership into the renderer or browser adapter.

## Failure, Concurrency, and Constraints

Package composition does not add I/O, await points, or cross-module mutable
state to the graph/rendering boundary. Each child module owns its own failure
and isolation contract.

## Verification and Change Impact

| Contract | Evidence owner | Required evidence |
| --- | --- | --- |
| Module contracts | child module tests/designs | Each affected module proves its own behavioral and target-specific invariants |
| Package composition | SwiftPM graph and consumer tests | Products resolve and expose the documented public modules |

Changes to a child module's public contract require updating that module design
and rerunning its direct tests plus the package consumer gates.
