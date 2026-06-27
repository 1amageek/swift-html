import JavaScriptKit
import SwiftHTMLClientRuntime

let document = JSObject.global.document.object!
let root = document.createElement!("div").object!
root.id = "client-runtime-swift-html-root"

let host = JavaScriptKitDOMHost(document: document)
let app = ClientHTMLDocument {
    main(.id("app"), .class("client-runtime-shell")) {
        h1 {
            "Client Runtime SwiftHTML"
        }
        p(.class("lead")) {
            "A small static SwiftHTML runtime mounted through the client runtime."
        }
        section(.class("counter-panel")) {
            output(.id("count-value"), .ariaLabel("Counter value")) {
                "Count 0"
            }
            button(.id("increment"), .type("button")) {
                "Increment"
            }
        }
        section(.class("input-panel")) {
            input(
                .id("name-input"),
                .type("text"),
                .placeholder("Enter a name"),
                .ariaLabel("Name")
            )
            output(.id("greeting"), .ariaLabel("Greeting")) {
                "Hello"
            }
        }
    }
}

app.mount(into: host, parent: root)
_ = document.body.object!.appendChild!(root)

let countOutput = document.getElementById!("count-value").object!
let incrementButton = document.getElementById!("increment").object!
var count = 0
incrementButton.onclick = JSValue.object(JSClosure { _ in
    count += 1
    countOutput.textContent = .string("Count \(count)")
    return .undefined
})

let nameInput = document.getElementById!("name-input").object!
let greeting = document.getElementById!("greeting").object!
nameInput.oninput = JSValue.object(JSClosure { _ in
    let name = nameInput.value.string ?? ""
    if name.isEmpty {
        greeting.textContent = .string("Hello")
    } else {
        greeting.textContent = .string("Hello, \(name)")
    }
    return .undefined
})

struct JavaScriptKitDOMHost: ClientDOMHost {
    let document: JSObject

    func createElement(_ tagName: String) -> JSObject {
        document.createElement!(tagName).object!
    }

    func createText(_ text: String) -> JSObject {
        document.createTextNode!(text).object!
    }

    func setAttribute(_ attribute: ClientHTMLAttribute, on node: JSObject) {
        _ = node.setAttribute!(attribute.name, attribute.value)
    }

    func appendChild(_ child: JSObject, to parent: JSObject) {
        _ = parent.appendChild!(child)
    }
}
