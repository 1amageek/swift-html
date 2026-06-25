# Environment Values

Use environment values for scoped data that should flow through component rendering.

## Environment Keys

Define an ``EnvironmentKey`` when a value has a default.

```swift
struct LocaleKey: EnvironmentKey {
    static let defaultValue = "en"
}

extension EnvironmentValues {
    var locale: String {
        get { self[LocaleKey.self] }
        set { self[LocaleKey.self] = newValue }
    }
}
```

Read the value with ``Environment``:

```swift
struct LocaleLabel: Component {
    @Environment(LocaleKey.self) private var locale: String

    var body: some HTML {
        span {
            locale
        }
    }
}
```

Set the value on any HTML value:

```swift
LocaleLabel()
    .environment(LocaleKey.self, "ja")
```

## Client-Safe Environment

Use ``ClientEnvironmentKey`` for values that can be encoded into hydration metadata.

```swift
struct ThemeKey: ClientEnvironmentKey {
    static let defaultValue = "system"
}
```

Client environment values must be `Codable` and `Sendable`.

## Type-Based Environment

Type-based environment reads are optional because no type can provide a universal default value.

```swift
struct Library: Sendable {
    let title: String
}

struct LibraryReader: Component {
    @Environment(Library.self) private var library: Library?

    var body: some HTML {
        if let library {
            span {
                library.title
            }
        } else {
            span {
                "Library unavailable"
            }
        }
    }
}
```

Provide a type-based value with `.environment(_:)`:

```swift
LibraryReader()
    .environment(Library(title: "Main"))
```

## Context Keys

``Context`` and ``ContextKey`` are domain naming conveniences backed by the same ``EnvironmentValues`` storage. They are not a separate provider system.

Use them when the call site should read like domain context rather than general environment.

## Visibility

Environment visibility controls hydration diagnostics.

| Visibility | Meaning |
|---|---|
| `serverOnly` | The value must not cross into client hydration snapshots. |
| `client` | The value may be encoded into client snapshots. |
| `runtimeOnly` | The value is available during render but not encoded for client reconstruction. |
