# Getting Started

Create typed HTML from Swift values and render it as an HTML string or a render artifact.

## Copyable Page Example

This example is a complete copyable starting point. It defines input data, an
``HTMLDocument``, and a render function.

```swift
import SwiftHTML

struct ProductSummary: Sendable {
    let id: String
    let title: String
    let price: String
    let href: String
}

struct ProductGridDocument: HTMLDocument {
    let products: [ProductSummary]

    var head: some Component {
        meta(.charset("utf-8"))
        title("Products")
    }

    var body: some Component {
        main(.class("product-grid")) {
            h1("Products")
            p(.class("lead"), text: "A typed SwiftHTML page rendered on the server.")

            section(.aria("label", "Products")) {
                ForEach(products, id: { product in product.id }) { product in
                    productCard(product)
                }
            }
        }
        .style {
            .maxWidth("840px")
            .margin("0 auto")
            .padding("32px")
            .font("16px -apple-system, BlinkMacSystemFont, sans-serif")
        }
    }

    private func productCard(_ product: ProductSummary) -> some Component {
        article(.class("product-card")) {
            h2 {
                a(.href(product.href)) {
                    product.title
                }
            }
            p(.class("price"), text: product.price)
        }
        .style {
            .padding("16px")
            .border("1px solid color-mix(in srgb, CanvasText 16%, transparent)")
            .borderRadius("8px")
        }
    }
}

func renderProductGridPage() -> String {
    ProductGridDocument(
        products: [
            ProductSummary(id: "keyboard", title: "Keyboard", price: "$129", href: "/products/keyboard"),
            ProductSummary(id: "trackpad", title: "Trackpad", price: "$149", href: "/products/trackpad"),
        ]
    )
    .render()
}
```

`head` and `body` are built with ``HTMLBuilder``. Builder content must conform
to ``Component`` and may contain tags, components, strings, control flow,
and `ForEach`. A complete document cannot be nested in either section.

## Render HTML

Use ``HTML/render()`` when you only need server-side HTML output:

```swift
let html = renderProductGridPage()
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
let artifact = ProductGridDocument(
    products: [
        ProductSummary(id: "keyboard", title: "Keyboard", price: "$129", href: "/products/keyboard"),
    ]
)
.renderArtifact()

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
