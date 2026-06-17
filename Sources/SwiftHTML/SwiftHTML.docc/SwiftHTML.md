# ``SwiftHTML``

Build typed HTML, render artifacts, and browser-neutral hydration contracts from Swift values.

## Overview

SwiftHTML is a framework-neutral HTML engine. It provides a declarative DSL for HTML tags, a component model, typed attributes, typed CSS helpers, render artifacts, graph diffing, state and environment support, action contracts, and runtime data structures for hydration.

SwiftHTML does not own HTTP routing, request and response objects, server action dispatch, security middleware, design-system components, JavaScriptKit, or a concrete WebAssembly bootstrap. Those responsibilities belong to higher-level packages.

| Layer | Responsibility |
|---|---|
| SwiftHTML | HTML DSL, rendering, diffing, state, environment, CSS, actions as render contracts, hydration records, browser command contracts. |
| SwiftHTMLPreview | Xcode preview bridge, SwiftUI host view, and WebKit preview surface. |
| Server framework | HTTP routing, request/response integration, CSRF/CORS/Origin policy, redirect policy, server action dispatch. |
| UI/runtime package | Visual components, theme defaults, JavaScriptKit adapter, WASM bootstrap, concrete DOM host. |

Use ``HTML/render()`` when you only need an HTML string. Use ``HTML/renderArtifact(environment:stateStore:options:)`` when a server or runtime needs diagnostics, hydration metadata, event handlers, DOM snapshots, or browser commands.

```swift
import SwiftHTML

struct HomePage: Component {
    var body: some HTML {
        document {
            html {
                head {
                    meta(.charset("utf-8"))
                    title("SwiftHTML")
                }
                body {
                    main(.class("page")) {
                        h1("SwiftHTML")
                        p("Typed HTML rendered from Swift values.")
                    }
                }
            }
        }
    }
}

let artifact = HomePage().renderArtifact()
print(artifact.html)
```

## Topics

### Start Here

- <doc:GettingStarted>
- <doc:HTMLDSL>
- <doc:RenderingAndDiagnostics>

### Component Model

- ``HTML``
- ``Component``
- ``ServerComponent``
- ``ClientComponent``
- ``HTMLBuilder``
- ``ForEach``
- ``Group``
- ``EmptyHTML``
- ``text``
- ``rawHTML``

### HTML Elements And Attributes

- ``Element``
- ``ElementRepresentable``
- ``ContainerElement``
- ``VoidElement``
- ``HTMLAttribute``
- ``HTMLAttributeKind``
- ``DOMEvent``
- ``DOMEventHandler``
- ``InputType``
- ``FormMethod``
- ``ButtonType``

### CSS

- <doc:Styling>
- ``Style``
- ``StyleBuilder``
- ``Stylesheet``
- ``StylesheetBuilder``
- ``CSSRule``
- ``CSSSelector``

### Rendering And Diffing

- ``HTMLRenderer``
- ``HTMLRenderOptions``
- ``RenderArtifact``
- ``RenderDiagnostic``
- ``RenderDiagnosticError``
- ``HTMLPatch``
- ``HTMLDOMSnapshot``
- ``HTMLDOMSerializer``

### State And Hydration

- <doc:StateAndHydration>
- ``State``
- ``Binding``
- ``StateStore``
- ``StateSlotID``
- ``StateSlotRecord``
- ``HydrationManifest``
- ``ClientHandlerManifest``
- ``BrowserHydrationIndex``
- ``BrowserHydrationRuntime``
- ``HydrationRuntimeSession``

### Environment

- <doc:EnvironmentValuesGuide>
- ``Environment``
- ``EnvironmentValues``
- ``EnvironmentKey``
- ``ClientEnvironmentKey``
- ``Context``
- ``ContextKey``
- ``ClientEnvironmentSnapshot``

### Actions

- <doc:Actions>
- ``ActionRepresentable``
- ``Action``
- ``ActionField``

### Runtime Contracts

- <doc:RuntimeContracts>
- ``BrowserDOMHost``
- ``BrowserDOMCommand``
- ``BrowserDOMCommandBatch``
- ``BrowserDOMCommandBuffer``
- ``BrowserDOMCommandEncoder``
- ``HydrationRuntimeUpdate``

### Loading

- ``ClientBundleManifest``
- ``ClientBundlePlanner``
- ``ClientBundleLoadResolver``
- ``ClientBundleLoadPlan``
- ``ClientBundleLoadingRuntime``
- ``ClientLoadPolicy``
- ``ClientSymbolGraph``
- ``WasmAsset``

### Boundaries And Safety

- <doc:SecurityAndBoundaries>
