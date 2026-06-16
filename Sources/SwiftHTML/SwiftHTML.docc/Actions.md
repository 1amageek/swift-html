# Actions

Use actions to describe an executable intent in rendered HTML without coupling SwiftHTML to a transport.

## Action Contracts

``ActionRepresentable`` is a small render contract:

```swift
struct SaveProfileAction: ActionRepresentable {
    let path = "/actions/save-profile"
    let method = FormMethod.post
    let fields = [
        ActionField("scope", "profile")
    ]
}
```

SwiftHTML can render the path, method, and hidden fields. It does not submit requests, validate CSRF, invoke server actors, or route HTTP traffic.

## Default Action Type

Use ``Action`` when a custom type is not needed.

```swift
let action = Action.post(
    "/actions/increment",
    fields: [
        ActionField("delta", 1),
        ActionField("source", "button")
    ]
)
```

## Hidden Fields

Action fields are regular name/value pairs:

```swift
let fields = action.fields
```

Higher-level packages can render them into forms, buttons, fetch payloads, server action envelopes, or distributed actor invocation messages.

## Boundary

| Concern | Owner |
|---|---|
| Path, method, hidden field representation | SwiftHTML |
| CSRF token generation and validation | Server framework |
| Origin and CORS policy | Server framework |
| HTTP request decoding | Server framework |
| Server action resolution | Server framework |
| Distributed actor invocation | Server framework |

This keeps SwiftHTML usable outside a specific web server or actor runtime.
