# Getting Started

Create typed HTML from Swift values and render it as an HTML string or a render artifact.

## Declare A Component

A component is a value that conforms to ``Component`` and returns `body`.

```swift
import SwiftHTML

struct ProductSummary: Component {
    let title: String
    let price: String

    var body: some HTML {
        article(.class("product-summary")) {
            h2(title)
            p(.class("price"), text: price)
            a(.href("/checkout")) {
                "Checkout"
            }
        }
    }
}
```

`body` is built with ``HTMLBuilder``. Builder content may contain tags, components, strings, control flow, and `ForEach`.

## Render HTML

Use ``HTML/render()`` when you only need server-side HTML output:

```swift
let html = ProductSummary(
    title: "Keyboard",
    price: "$129"
).render()
```

SwiftHTML escapes text nodes and normal attribute values:

```swift
let html = div(.id("root")) {
    "5 > 3 & 2 < 4"
}
.render()
```

The output contains escaped text:

```html
<div id="root">5 &gt; 3 &amp; 2 &lt; 4</div>
```

## Render An Artifact

Use ``HTML/renderArtifact(environment:stateStore:options:)`` when a higher-level package needs metadata in addition to the HTML string.

```swift
let artifact = ProductSummary(
    title: "Keyboard",
    price: "$129"
).renderArtifact()

print(artifact.html)
print(artifact.diagnostics)
print(artifact.hydration.components)
```

``RenderArtifact`` exposes a safe facade. The raw render graph remains an internal implementation detail.

## Choose The Right Surface

| Need | API |
|---|---|
| Static HTML string | ``HTML/render()`` |
| Diagnostics and hydration metadata | ``HTML/renderArtifact(environment:stateStore:options:)`` |
| Custom rendering pipeline | ``HTMLRenderer`` |
| Runtime state across renders | ``StateStore`` |
| Hydration event dispatch | ``BrowserHydrationRuntime`` |

## Next Steps

- <doc:HTMLDSL>
- <doc:Styling>
- <doc:StateAndHydration>
