# Security And Boundaries

SwiftHTML is a rendering and runtime-contract package, not an HTTP security framework.

## Rendering Safety

| Surface | SwiftHTML behavior |
|---|---|
| Text nodes | Escaped by default. |
| Normal attributes | Escaped by default. |
| URL attributes | Typed URL attributes reject unsafe JavaScript URLs. |
| Event attributes | Stored as runtime handler records; inline JavaScript strings are not emitted. |
| `rawHTML` | Emits authored HTML. Use only with trusted content. |
| CSS selectors and values | Serialized as authored. Validate untrusted input before passing it to CSS APIs. |

## Framework Boundary

Security that depends on requests, origins, cookies, proxies, and HTTP responses belongs above SwiftHTML.

| Concern | Owner |
|---|---|
| CSRF token generation and validation | Server framework |
| Origin and Referer validation | Server framework |
| CORS policy | Server framework |
| Redirect allowlists | Server framework |
| Security headers | Server framework |
| Cookie policy | Server framework |
| Trusted proxy and forwarded headers | Server framework |
| Upload body parsing | Server framework |

SwiftHTML can render action fields and forms, but it cannot decide whether a request is authorized or whether an origin is trusted.

## Raw HTML

Use ``rawHTML`` only for trusted content:

```swift
article {
    rawHTML("<strong>Trusted content</strong>")
}
```

Do not use `rawHTML` for user-authored content unless it has already been sanitized by an application-specific sanitizer.

## CSS Input

CSS selector and value APIs are escape hatches. They preserve authored CSS and are not sanitizers.

```swift
let style = Style.custom("--trusted-token", "var(--accent)")
let selector = CSSSelector(".trusted-class")
```

Validate untrusted input before passing it to:

- `Style.custom(_:_:)`
- Dynamic ``Style`` members
- ``CSSSelector``
- ``CSSRule``
- Raw `style` attributes

## Hydration Boundary

Client-owned components can capture event handlers and state. Server-only values should not cross into hydration snapshots.

Use diagnostics and ``RenderArtifact/validateHydration()`` to enforce clean boundaries in tests and development runtime entry points.
