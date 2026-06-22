# Styling

Use `Style` for inline declarations and `Stylesheet` for selector-based CSS rules.

## Inline Styles

``Style`` stores CSS declarations as data before serialization.

```swift
div {
    "Panel"
}
.style {
    .display("grid")
    .gridTemplateColumns("1fr auto")
    .gap("12px")
    .whiteSpace("nowrap")
    .custom("--panel-tone", "muted")
}
```

The generated CSS property surface is based on `@mdn/browser-compat-data`. Standard-track, non-deprecated, non-vendor properties are exposed as static ``Style`` helpers.

## Dynamic And Custom Properties

Use `Style.custom(_:_:)` for CSS custom properties, vendor-prefixed properties, platform experiments, and newly standardized CSS before the generated list is refreshed.

```swift
Style {
    .custom("--accent-color", "oklch(62% 0.18 250)")
    .custom("-webkit-font-smoothing", "antialiased")
}
```

Dynamic member lookup is also available:

```swift
let style = Style.opacity("0.8")
    .gridTemplateColumns("1fr 2fr")
```

## Stylesheets

Use ``Stylesheet`` and ``CSSRule`` when CSS belongs in a `style` element or generated asset.

```swift
let stylesheet = Stylesheet {
    rule(".panel") {
        .minHeight("36px")
        .background("var(--panel-background)")
        .borderRadius("8px")
    }

    rule(".panel[data-active=\"true\"]") {
        .outline("2px solid var(--accent)")
    }
}

print(stylesheet.cssText)
```

## At-Rules And Timing

Stylesheets compose typed at-rules instead of raw CSS strings: ``media(_:_:)``,
``supports(_:_:)``, ``startingStyle(_:)``, and ``keyframes(_:_:)`` (whose body is a
list of ``Keyframe`` selectors). ``TimingFunction`` provides CSS easings —
`.linear`, `.ease`, `.easeIn`, `.easeOut`, `.easeInOut`, ``TimingFunction/cubicBezier(_:_:_:_:)``,
``TimingFunction/steps(_:_:)``, and ``TimingFunction/spring(bounce:)`` (sampled as a
`linear()` easing).

```swift
let stylesheet = Stylesheet {
    rule(".sheet") {
        .transition("opacity 0.3s \(TimingFunction.easeInOut.cssValue)")
    }
    startingStyle {
        rule(".sheet") { .opacity("0") }
    }
    keyframes("pulse") {
        Keyframe("from") { .opacity("1") }
        Keyframe("to") { .opacity("0.4") }
    }
    media("(prefers-reduced-motion: reduce)") {
        rule(".sheet") { .transitionDuration("0.01ms") }
    }
}
```

## Builder Control Flow

``StyleBuilder`` and ``StylesheetBuilder`` support ordinary Swift control flow.

```swift
let isCompact = true

let style = Style {
    .display("grid")
    if isCompact {
        .gap("8px")
    } else {
        .gap("16px")
    }
}
```

## Safety Contract

CSS selectors and values are serialized as authored.

| API | Contract |
|---|---|
| `Style.custom(_:_:)` | Writes the property name and value as provided. |
| Dynamic CSS members | Converts the Swift member name to a CSS property name and writes the value as provided. |
| ``CSSSelector`` | Writes the selector as provided. |
| ``CSSRule`` | Writes selector and declarations as provided. |
| Raw `style` attributes | Writes the attribute value as provided after attribute escaping. |

Validate or sanitize untrusted input before passing it to CSS APIs.

## Updating Generated Properties

Run the generator from the package root:

```bash
node scripts/generate-swift-html-css-properties.mjs
node scripts/generate-swift-html-css-properties.mjs --check
```
