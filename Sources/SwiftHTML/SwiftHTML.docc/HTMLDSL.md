# HTML DSL

Use lowercase Swift types for HTML tags, typed attributes for standard HTML behavior, and `Element` for custom elements.

## Tags

SwiftHTML tags intentionally mirror DOM tag names.

```swift
section(.id("intro")) {
    h1("SwiftHTML")
    p("Typed HTML rendered from Swift.")
}
```

Container tags accept builder content. Void tags accept attributes:

```swift
form(.method(.post), .action("/subscribe")) {
    label(.`for`("email")) {
        "Email"
    }
    input(
        .id("email"),
        .type(.email),
        .name("email"),
        .required
    )
    button(.type(.submit)) {
        "Subscribe"
    }
}
```

## Text

Text can be written as a builder string or as a tag initializer shortcut.

```swift
section {
    h2("Client Counter")
    p(.class("lead"), text: "State can belong to a ClientComponent.")
}
```

Use ``rawHTML`` only for trusted HTML fragments.

```swift
div {
    rawHTML("<strong>Trusted markup</strong>")
}
```

## Attributes

Typed attributes keep common HTML behavior discoverable:

```swift
a(
    .href("/account"),
    .data("tracking-id", "account-link"),
    .aria("label", "Open account")
) {
    "Account"
}
```

Use ``HTMLAttribute/attribute(_:_:)`` for an attribute that SwiftHTML does not yet model explicitly.

```swift
div(.attribute("popover", "auto")) {
    "Popover content"
}
```

## Custom Elements

Use ``Element`` for custom elements and platform experiments.

```swift
Element("custom-card", attributes: [
    .attribute("variant", "compact")
]) {
    h3("Custom element")
}
```

## Control Flow

Builder control flow supports `if`, `switch`, loops, and ``ForEach``.

```swift
struct NavigationMenu: Component {
    enum Mode {
        case signedOut
        case signedIn
    }

    let mode: Mode
    let items: [String]

    var body: some HTML {
        nav {
            ul {
                ForEach(items, id: { item in item }) { item in
                    li {
                        a(.href("/\(item)")) {
                            item
                        }
                    }
                }
            }

            switch mode {
            case .signedOut:
                a(.href("/login")) {
                    "Sign in"
                }
            case .signedIn:
                button(.type(ButtonType.button)) {
                    "Sign out"
                }
            }
        }
    }
}
```

## Identity

Use stable keys when stateful or hydrated children may reorder.

```swift
ForEach(rows, id: { row in row.id }) { row in
    RowView(row: row)
}
```

Stable identity lets SwiftHTML preserve component state and emit smaller DOM patches.
