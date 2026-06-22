# Changelog

## 0.6.4 - 2026-06-22

| Area | Included |
|---|---|
| Timing | `TimingFunction.spring` drops its unused `duration` parameter — the easing is normalized over its timeline, so the caller sets duration as the transition/animation duration rather than a curve parameter. The factory is now `spring(bounce:)`. |

## 0.6.3 - 2026-06-22

Adds CSS animation primitives.

| Area | Included |
|---|---|
| Timing | New `TimingFunction` value type: cubic-bezier presets (`ease`/`easeIn`/`easeOut`/`easeInOut`/`linear`), `cubicBezier`, `steps`, and `spring(duration:bounce:)` approximated as a sampled `linear()` easing. |
| At-rules | `Stylesheet` models `@media`/`@supports`/`@starting-style`/`@keyframes` as typed items (`media`/`supports`/`startingStyle`/`keyframes` + `Keyframe`), so a stylesheet needs no raw CSS strings. `Stylesheet.items` is the full list; `Stylesheet.rules` still returns the flat top-level rules. |

## 0.6.2 - 2026-06-22

Hardens the runtime against silent failures.

| Area | Included |
|---|---|
| State | A `@State` snapshot whose type matches its slot but fails to decode now reports the failure to stderr instead of silently resetting the value to its default during hydration. Restores that are impossible by design (non-JSON encoding, non-`Decodable` type) still fall through to the default quietly. |
| Rendering | The enlarged-stack render worker always signals its completion semaphore via `defer`, so an abnormal worker exit surfaces as the `box.take()` precondition failure instead of deadlocking the calling thread. |

## 0.6.1 - 2026-06-22

Removes the `@HTMLAttributeBuilder` introduced in 0.6.0. Swift cannot express a clean per-line attribute syntax — consecutive leading-dot factories chain into method calls, and lowercase attribute functions collide with the same-named tag types — so the builder did not improve on plain attribute arrays. The enlarged-stack rendering fix from 0.6.0 is unaffected.

| Area | Included |
|---|---|
| Attributes | Removed `@HTMLAttributeBuilder` and its `Element` / container / void tag initializers. Compose attributes with initializer arguments and arrays, as before. |

## 0.6.0 - 2026-06-21

Fixes deep-tree rendering and adds a declarative attribute builder.

| Area | Included |
|---|---|
| Rendering | `HTMLRenderer.render` now builds and serializes on a dedicated enlarged-stack thread so deeply composed (statically typed) trees no longer overflow the runtime's type-metadata decoder. No type erasure of the public DSL. |
| Attributes | New `@HTMLAttributeBuilder` and matching `Element` / container / void tag initializers compose conditional or assembled attribute lists declaratively (`if`/`switch`/`for`, plus `[HTMLAttribute]` splicing) instead of `(cond ? [x] : []) + extra`. |
| Documentation | README and `docs/SwiftHTML.md` document the attribute builder. |

## 0.5.0 - 2026-06-19

Simplifies Xcode preview support by using SwiftUI's built-in `#Preview` as the only preview discovery entry point.

| Area | Included |
|---|---|
| Preview | Replaced the freestanding preview macro with the `HTMLPreview` SwiftUI view. |
| API | Removed public preview configuration and viewport types; use `.style(_:)`, `.language(_:)`, `.baseURL(_:)`, and `.renderOptions(_:)` on `HTMLPreview`. |
| Package | Removed the SwiftSyntax macro dependency from `SwiftHTMLPreview`. |
| Documentation | Updated README and DocC examples to use `#Preview { HTMLPreview { ... } }`. |

## 0.3.0 - 2026-06-17

Promotes state and hydration runtime contracts for client WASM runtimes and component-level HMR.

| Area | Included |
|---|---|
| State | New `StateStoreSnapshot`, `StateSnapshotValue`, `StateSnapshotError`, and `StateSchema` public contracts. |
| Hydration | Browser hydration component records now carry state slots and derived state schema hashes. |
| Loading | `ClientComponentAsset` now includes state and environment schema hashes for split WASM loading. |
| Runtime | `StateStore` can snapshot and restore Codable state behind a schema guard. |
| Documentation | README and DocC now describe runtime snapshot and schema preservation semantics. |

## 0.2.0 - 2026-06-17

Adds Xcode preview support for SwiftHTML.

| Area | Included |
|---|---|
| Preview | New `SwiftHTMLPreview` product with `#HTMLPreview`, `HTMLPreviewHost`, `HTMLPreviewRenderer`, `HTMLPreviewConfiguration`, and `HTMLPreviewViewport`. |
| Macro | New `SwiftHTMLPreviewMacros` target that expands `#HTMLPreview` directly to SwiftUI `#Preview` while forwarding preview traits. |
| Documentation | README and DocC coverage for preview usage, configuration, and build behavior. |
| Tests | Preview renderer tests, compile smoke tests, and macro expansion tests. |
| Tooling | Swift package tools version remains Swift 6.3. |

## 0.1.0 - 2026-06-16

Initial public release.

| Area | Included |
|---|---|
| HTML DSL | Lowercase HTML tags, typed attributes, text initializer shortcuts, raw HTML, and builder control flow. |
| Components | `Component`, `ServerComponent`, `ClientComponent`, `@State`, `Binding`, and environment propagation. |
| Rendering | HTML string rendering, render artifacts, diagnostics, hydration manifests, and internal graph diffing. |
| CSS | `Style`, generated standard CSS property helpers, `@StyleBuilder`, `Stylesheet`, `CSSRule`, and `@StylesheetBuilder`. |
| Hydration | Browser hydration indexes, DOM patch commands, command batches, and browser host contracts. |
| Loading | Split WASM bundle manifests, load plans, and loading runtime contracts. |
| Actions | `ActionRepresentable`, `Action`, `ActionField`, and hidden-field rendering contracts. |
