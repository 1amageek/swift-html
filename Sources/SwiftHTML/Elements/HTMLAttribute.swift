public struct DOMEvent: Sendable, Codable, Equatable {
    public let value: String?
    public let checked: Bool?
    public let key: String?
    public let code: String?
    public let inputType: String?
    public let clientX: Double?
    public let clientY: Double?
    public let metadata: [String: String]

    public init(
        value: String? = nil,
        checked: Bool? = nil,
        key: String? = nil,
        code: String? = nil,
        inputType: String? = nil,
        clientX: Double? = nil,
        clientY: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.value = value
        self.checked = checked
        self.key = key
        self.code = code
        self.inputType = inputType
        self.clientX = clientX
        self.clientY = clientY
        self.metadata = metadata
    }

    public subscript(_ name: String) -> String? {
        metadata[name]
    }
}

public final class DOMEventHandler {
    private let handler: (DOMEvent) -> Void

    public init(_ handler: @escaping (DOMEvent) -> Void) {
        self.handler = handler
    }

    public func invoke(with event: DOMEvent = DOMEvent()) {
        handler(event)
    }
}

public enum HTMLAttributeKind: Sendable, Equatable, Codable {
    case string
    case boolean
    case tokenList
    case url
    case urlList
    case propertyBinding
    case eventBinding
    case raw
}

public struct HTMLAttribute {
    public let name: String
    public let value: String?
    public let kind: HTMLAttributeKind
    let eventName: String?
    let eventHandler: DOMEventHandler?

    public init(_ name: String, _ value: String? = nil) {
        self.name = name
        self.value = value
        self.kind = value == nil ? .boolean : .string
        self.eventName = nil
        self.eventHandler = nil
    }

    public init(name: String, value: String?, kind: HTMLAttributeKind) {
        self.name = name
        self.value = value
        self.kind = kind
        self.eventName = nil
        self.eventHandler = nil
    }

    init(eventName: String, handler: @escaping (DOMEvent) -> Void) {
        self.name = "on\(eventName)"
        self.value = nil
        self.kind = .eventBinding
        self.eventName = eventName
        if let context = StateContext.current {
            self.eventHandler = DOMEventHandler { event in
                StateContext.withValue(context) {
                    handler(event)
                }
            }
        } else {
            self.eventHandler = DOMEventHandler(handler)
        }
    }
}

public enum InputType: String, Sendable {
    case button
    case checkbox
    case color
    case date
    case datetimeLocal = "datetime-local"
    case email
    case file
    case hidden
    case image
    case month
    case number
    case password
    case radio
    case range
    case reset
    case search
    case submit
    case tel
    case text
    case time
    case url
    case week
}

public enum FormMethod: String, Sendable, Codable {
    case get
    case post
    case dialog
}

public enum ButtonType: String, Sendable {
    case button
    case submit
    case reset
}

public enum Target: String, Sendable {
    case blank = "_blank"
    case `self` = "_self"
    case parent = "_parent"
    case top = "_top"
}

public enum Direction: String, Sendable {
    case ltr
    case rtl
    case auto
}

public enum Loading: String, Sendable {
    case eager
    case lazy
}

public enum CrossOrigin: String, Sendable {
    case anonymous
    case useCredentials = "use-credentials"
}

public enum ReferrerPolicy: String, Sendable {
    case noReferrer = "no-referrer"
    case noReferrerWhenDowngrade = "no-referrer-when-downgrade"
    case origin
    case originWhenCrossOrigin = "origin-when-cross-origin"
    case sameOrigin = "same-origin"
    case strictOrigin = "strict-origin"
    case strictOriginWhenCrossOrigin = "strict-origin-when-cross-origin"
    case unsafeURL = "unsafe-url"
}

public enum FetchPriority: String, Sendable {
    case high
    case low
    case auto
}

public enum Decoding: String, Sendable {
    case sync
    case async
    case auto
}

public enum InputMode: String, Sendable {
    case none
    case text
    case decimal
    case numeric
    case tel
    case search
    case email
    case url
}

public enum EnterKeyHint: String, Sendable {
    case enter
    case done
    case go
    case next
    case previous
    case search
    case send
}

public enum Autocapitalize: String, Sendable {
    case off
    case none
    case on
    case sentences
    case words
    case characters
}

public enum Autocorrect: String, Sendable {
    case on
    case off
}

public enum VirtualKeyboardPolicy: String, Sendable {
    case auto
    case manual
}

public enum WritingSuggestions: String, Sendable {
    case enabled = "true"
    case disabled = "false"
}

public enum TableScope: String, Sendable {
    case row
    case col
    case rowgroup
    case colgroup
}

public enum TextareaWrap: String, Sendable {
    case hard
    case soft
    case off
}

public enum Preload: String, Sendable {
    case none
    case metadata
    case auto
}

public enum TrackKind: String, Sendable {
    case subtitles
    case captions
    case descriptions
    case chapters
    case metadata
}

public enum DialogClosedBy: String, Sendable {
    case any
    case closeRequest = "closerequest"
    case none
}

public enum PopoverTargetAction: String, Sendable {
    case hide
    case show
    case toggle
}

public extension HTMLAttribute {
    static func attribute(_ name: String, _ value: String? = nil) -> HTMLAttribute {
        HTMLAttribute(name, value)
    }

    static func property(_ name: String, _ value: String? = nil) -> HTMLAttribute {
        HTMLAttribute(name: name, value: value, kind: .propertyBinding)
    }

    static func id(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "id", value: value, kind: .string) }
    static func `class`(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "class", value: value, kind: .tokenList) }
    static func style(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "style", value: value, kind: .string) }
    static func style(_ style: Style) -> HTMLAttribute { HTMLAttribute(name: "style", value: style.cssText, kind: .string) }
    static func style(@StyleBuilder _ content: () -> Style) -> HTMLAttribute { .style(content()) }
    static func title(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "title", value: value, kind: .string) }
    static func lang(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "lang", value: value, kind: .string) }
    static func dir(_ value: Direction) -> HTMLAttribute { HTMLAttribute(name: "dir", value: value.rawValue, kind: .string) }
    static var hidden: HTMLAttribute { HTMLAttribute(name: "hidden", value: nil, kind: .boolean) }
    static var inert: HTMLAttribute { HTMLAttribute(name: "inert", value: nil, kind: .boolean) }
    static func tabindex(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "tabindex", value: String(value), kind: .string) }
    static func accesskey(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "accesskey", value: value, kind: .tokenList) }
    static func contenteditable(_ value: Bool) -> HTMLAttribute { HTMLAttribute(name: "contenteditable", value: String(value), kind: .string) }
    static func draggable(_ value: Bool) -> HTMLAttribute { HTMLAttribute(name: "draggable", value: String(value), kind: .string) }
    static func spellcheck(_ value: Bool) -> HTMLAttribute { HTMLAttribute(name: "spellcheck", value: String(value), kind: .string) }
    static func translate(_ value: Bool) -> HTMLAttribute { HTMLAttribute(name: "translate", value: value ? "yes" : "no", kind: .string) }
    static var autofocus: HTMLAttribute { HTMLAttribute(name: "autofocus", value: nil, kind: .boolean) }
    static func nonce(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "nonce", value: value, kind: .string) }
    static func role(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "role", value: value, kind: .string) }
    static func data(_ name: String, _ value: String) -> HTMLAttribute { HTMLAttribute(name: "data-\(name)", value: value, kind: .string) }
    static func aria(_ name: String, _ value: String) -> HTMLAttribute { HTMLAttribute(name: "aria-\(name)", value: value, kind: .string) }
    static func slot(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "slot", value: value, kind: .string) }
    static func part(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "part", value: value, kind: .tokenList) }
    static func exportparts(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "exportparts", value: value, kind: .tokenList) }
    static func `is`(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "is", value: value, kind: .string) }
    static func itemprop(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "itemprop", value: value, kind: .tokenList) }
    static var itemscope: HTMLAttribute { HTMLAttribute(name: "itemscope", value: nil, kind: .boolean) }
    static func itemtype(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "itemtype", value: value, kind: .url) }
    static func itemid(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "itemid", value: value, kind: .url) }
    static func itemref(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "itemref", value: value, kind: .tokenList) }

    static func href(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "href", value: value, kind: .url) }
    static func src(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "src", value: value, kind: .url) }
    static func alt(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "alt", value: value, kind: .string) }
    static func srcset(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "srcset", value: value, kind: .urlList) }
    static func sizes(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "sizes", value: value, kind: .string) }
    static func imagesrcset(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "imagesrcset", value: value, kind: .urlList) }
    static func imagesizes(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "imagesizes", value: value, kind: .string) }
    static func poster(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "poster", value: value, kind: .url) }
    static func cite(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "cite", value: value, kind: .url) }
    static func action(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "action", value: value, kind: .url) }
    static func formaction(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "formaction", value: value, kind: .url) }
    static func manifest(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "manifest", value: value, kind: .url) }
    static func ping(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "ping", value: value, kind: .urlList) }
    static func usemap(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "usemap", value: value, kind: .string) }
    static var ismap: HTMLAttribute { HTMLAttribute(name: "ismap", value: nil, kind: .boolean) }
    static func srcdoc(_ value: String) -> HTMLAttribute {
        HTMLAttribute(name: "srcdoc", value: HTMLWriter.escapeText(value), kind: .string)
    }

    static func srcdoc(_ value: rawHTML) -> HTMLAttribute {
        HTMLAttribute(name: "srcdoc", value: value.value, kind: .raw)
    }
    static func download(_ value: String? = nil) -> HTMLAttribute { HTMLAttribute(name: "download", value: value, kind: value == nil ? .boolean : .string) }
    static func crossorigin(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "crossorigin", value: value, kind: .string) }
    static func crossorigin(_ value: CrossOrigin) -> HTMLAttribute { HTMLAttribute(name: "crossorigin", value: value.rawValue, kind: .string) }
    static func integrity(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "integrity", value: value, kind: .string) }
    static func referrerpolicy(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "referrerpolicy", value: value, kind: .string) }
    static func referrerpolicy(_ value: ReferrerPolicy) -> HTMLAttribute { HTMLAttribute(name: "referrerpolicy", value: value.rawValue, kind: .string) }
    static func fetchpriority(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "fetchpriority", value: value, kind: .string) }
    static func fetchpriority(_ value: FetchPriority) -> HTMLAttribute { HTMLAttribute(name: "fetchpriority", value: value.rawValue, kind: .string) }
    static func loading(_ value: Loading) -> HTMLAttribute { HTMLAttribute(name: "loading", value: value.rawValue, kind: .string) }
    static func decoding(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "decoding", value: value, kind: .string) }
    static func decoding(_ value: Decoding) -> HTMLAttribute { HTMLAttribute(name: "decoding", value: value.rawValue, kind: .string) }
    static func sandbox(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "sandbox", value: value, kind: .tokenList) }
    static func allow(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "allow", value: value, kind: .string) }
    static var allowfullscreen: HTMLAttribute { HTMLAttribute(name: "allowfullscreen", value: nil, kind: .boolean) }

    static func method(_ value: FormMethod) -> HTMLAttribute { HTMLAttribute(name: "method", value: value.rawValue, kind: .string) }
    static func enctype(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "enctype", value: value, kind: .string) }
    static func target(_ value: Target) -> HTMLAttribute { HTMLAttribute(name: "target", value: value.rawValue, kind: .string) }
    static func target(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "target", value: value, kind: .string) }
    static func acceptCharset(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "accept-charset", value: value, kind: .string) }
    static var novalidate: HTMLAttribute { HTMLAttribute(name: "novalidate", value: nil, kind: .boolean) }
    static func autocomplete(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "autocomplete", value: value, kind: .string) }
    static func rel(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "rel", value: value, kind: .tokenList) }

    static func name(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "name", value: value, kind: .string) }
    static func value(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "value", value: value, kind: .string) }
    static func value(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "value", value: String(value), kind: .string) }
    static func value(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "value", value: String(value), kind: .string) }
    static func value(_ binding: Binding<String>) -> HTMLAttribute {
        HTMLAttribute(name: "value", value: binding.wrappedValue, kind: .propertyBinding)
    }
    static func type(_ value: InputType) -> HTMLAttribute { HTMLAttribute(name: "type", value: value.rawValue, kind: .string) }
    static func type(_ value: ButtonType) -> HTMLAttribute { HTMLAttribute(name: "type", value: value.rawValue, kind: .string) }
    static func type(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "type", value: value, kind: .string) }
    static var checked: HTMLAttribute { HTMLAttribute(name: "checked", value: nil, kind: .boolean) }
    static func checked(_ binding: Binding<Bool>) -> HTMLAttribute {
        HTMLAttribute(name: "checked", value: String(binding.wrappedValue), kind: .propertyBinding)
    }
    static var selected: HTMLAttribute { HTMLAttribute(name: "selected", value: nil, kind: .boolean) }
    static func selected(_ binding: Binding<Bool>) -> HTMLAttribute {
        HTMLAttribute(name: "selected", value: String(binding.wrappedValue), kind: .propertyBinding)
    }
    static var disabled: HTMLAttribute { HTMLAttribute(name: "disabled", value: nil, kind: .boolean) }
    static func disabled(_ binding: Binding<Bool>) -> HTMLAttribute {
        HTMLAttribute(name: "disabled", value: String(binding.wrappedValue), kind: .propertyBinding)
    }
    static var readonly: HTMLAttribute { HTMLAttribute(name: "readonly", value: nil, kind: .boolean) }
    static var required: HTMLAttribute { HTMLAttribute(name: "required", value: nil, kind: .boolean) }
    static var multiple: HTMLAttribute { HTMLAttribute(name: "multiple", value: nil, kind: .boolean) }
    static func placeholder(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "placeholder", value: value, kind: .string) }
    static func pattern(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "pattern", value: value, kind: .string) }
    static func min(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "min", value: value, kind: .string) }
    static func min(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "min", value: String(value), kind: .string) }
    static func min(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "min", value: String(value), kind: .string) }
    static func max(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "max", value: value, kind: .string) }
    static func max(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "max", value: String(value), kind: .string) }
    static func max(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "max", value: String(value), kind: .string) }
    static func step(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "step", value: value, kind: .string) }
    static func step(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "step", value: String(value), kind: .string) }
    static func step(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "step", value: String(value), kind: .string) }
    static func minlength(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "minlength", value: String(value), kind: .string) }
    static func maxlength(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "maxlength", value: String(value), kind: .string) }
    static func size(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "size", value: String(value), kind: .string) }
    static func list(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "list", value: value, kind: .string) }
    static func accept(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "accept", value: value, kind: .string) }
    static func capture(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "capture", value: value, kind: .string) }
    static func dirname(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "dirname", value: value, kind: .string) }
    static func form(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "form", value: value, kind: .string) }
    static func formmethod(_ value: FormMethod) -> HTMLAttribute { HTMLAttribute(name: "formmethod", value: value.rawValue, kind: .string) }
    static func formenctype(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "formenctype", value: value, kind: .string) }
    static func formtarget(_ value: Target) -> HTMLAttribute { HTMLAttribute(name: "formtarget", value: value.rawValue, kind: .string) }
    static func formtarget(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "formtarget", value: value, kind: .string) }
    static var formnovalidate: HTMLAttribute { HTMLAttribute(name: "formnovalidate", value: nil, kind: .boolean) }
    static func inputmode(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "inputmode", value: value, kind: .string) }
    static func inputmode(_ value: InputMode) -> HTMLAttribute { HTMLAttribute(name: "inputmode", value: value.rawValue, kind: .string) }
    static func enterkeyhint(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "enterkeyhint", value: value, kind: .string) }
    static func enterkeyhint(_ value: EnterKeyHint) -> HTMLAttribute { HTMLAttribute(name: "enterkeyhint", value: value.rawValue, kind: .string) }
    static func autocapitalize(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "autocapitalize", value: value, kind: .string) }
    static func autocapitalize(_ value: Autocapitalize) -> HTMLAttribute { HTMLAttribute(name: "autocapitalize", value: value.rawValue, kind: .string) }
    static func autocorrect(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "autocorrect", value: value, kind: .string) }
    static func autocorrect(_ value: Autocorrect) -> HTMLAttribute { HTMLAttribute(name: "autocorrect", value: value.rawValue, kind: .string) }
    static func virtualkeyboardpolicy(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "virtualkeyboardpolicy", value: value, kind: .string) }
    static func virtualkeyboardpolicy(_ value: VirtualKeyboardPolicy) -> HTMLAttribute { HTMLAttribute(name: "virtualkeyboardpolicy", value: value.rawValue, kind: .string) }
    static func writingsuggestions(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "writingsuggestions", value: value, kind: .string) }
    static func writingsuggestions(_ value: WritingSuggestions) -> HTMLAttribute { HTMLAttribute(name: "writingsuggestions", value: value.rawValue, kind: .string) }
    static func `for`(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "for", value: value, kind: .string) }

    static func colspan(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "colspan", value: String(value), kind: .string) }
    static func rowspan(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "rowspan", value: String(value), kind: .string) }
    static func span(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "span", value: String(value), kind: .string) }
    static func headers(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "headers", value: value, kind: .tokenList) }
    static func scope(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "scope", value: value, kind: .string) }
    static func scope(_ value: TableScope) -> HTMLAttribute { HTMLAttribute(name: "scope", value: value.rawValue, kind: .string) }
    static func abbr(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "abbr", value: value, kind: .string) }
    static func width(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "width", value: String(value), kind: .string) }
    static func height(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "height", value: String(value), kind: .string) }
    static func rows(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "rows", value: String(value), kind: .string) }
    static func cols(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "cols", value: String(value), kind: .string) }
    static func wrap(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "wrap", value: value, kind: .string) }
    static func wrap(_ value: TextareaWrap) -> HTMLAttribute { HTMLAttribute(name: "wrap", value: value.rawValue, kind: .string) }
    static func low(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "low", value: String(value), kind: .string) }
    static func high(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "high", value: String(value), kind: .string) }
    static func optimum(_ value: Double) -> HTMLAttribute { HTMLAttribute(name: "optimum", value: String(value), kind: .string) }
    static var reversed: HTMLAttribute { HTMLAttribute(name: "reversed", value: nil, kind: .boolean) }
    static func start(_ value: Int) -> HTMLAttribute { HTMLAttribute(name: "start", value: String(value), kind: .string) }
    static func datetime(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "datetime", value: value, kind: .string) }
    static func coords(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "coords", value: value, kind: .string) }
    static func shape(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "shape", value: value, kind: .string) }

    static var controls: HTMLAttribute { HTMLAttribute(name: "controls", value: nil, kind: .boolean) }
    static var autoplay: HTMLAttribute { HTMLAttribute(name: "autoplay", value: nil, kind: .boolean) }
    static var muted: HTMLAttribute { HTMLAttribute(name: "muted", value: nil, kind: .boolean) }
    static var loop: HTMLAttribute { HTMLAttribute(name: "loop", value: nil, kind: .boolean) }
    static func preload(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "preload", value: value, kind: .string) }
    static func preload(_ value: Preload) -> HTMLAttribute { HTMLAttribute(name: "preload", value: value.rawValue, kind: .string) }
    static var playsinline: HTMLAttribute { HTMLAttribute(name: "playsinline", value: nil, kind: .boolean) }
    static func kind(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "kind", value: value, kind: .string) }
    static func kind(_ value: TrackKind) -> HTMLAttribute { HTMLAttribute(name: "kind", value: value.rawValue, kind: .string) }
    static func srclang(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "srclang", value: value, kind: .string) }
    static func label(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "label", value: value, kind: .string) }
    static var `default`: HTMLAttribute { HTMLAttribute(name: "default", value: nil, kind: .boolean) }

    static var `async`: HTMLAttribute { HTMLAttribute(name: "async", value: nil, kind: .boolean) }
    static var `defer`: HTMLAttribute { HTMLAttribute(name: "defer", value: nil, kind: .boolean) }
    static var nomodule: HTMLAttribute { HTMLAttribute(name: "nomodule", value: nil, kind: .boolean) }
    static func blocking(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "blocking", value: value, kind: .tokenList) }
    static func charset(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "charset", value: value, kind: .string) }
    static func `as`(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "as", value: value, kind: .string) }
    static func media(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "media", value: value, kind: .string) }
    static func hreflang(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "hreflang", value: value, kind: .string) }
    static func content(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "content", value: value, kind: .string) }
    static func httpEquiv(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "http-equiv", value: value, kind: .string) }
    static func color(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "color", value: value, kind: .string) }

    static var open: HTMLAttribute { HTMLAttribute(name: "open", value: nil, kind: .boolean) }
    static func closedby(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "closedby", value: value, kind: .string) }
    static func closedby(_ value: DialogClosedBy) -> HTMLAttribute { HTMLAttribute(name: "closedby", value: value.rawValue, kind: .string) }
    static func popover(_ value: String? = nil) -> HTMLAttribute { HTMLAttribute(name: "popover", value: value, kind: value == nil ? .boolean : .string) }
    static func popovertarget(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "popovertarget", value: value, kind: .string) }
    static func popovertargetaction(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "popovertargetaction", value: value, kind: .string) }
    static func popovertargetaction(_ value: PopoverTargetAction) -> HTMLAttribute { HTMLAttribute(name: "popovertargetaction", value: value.rawValue, kind: .string) }
    static func command(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "command", value: value, kind: .string) }
    static func commandfor(_ value: String) -> HTMLAttribute { HTMLAttribute(name: "commandfor", value: value, kind: .string) }

    static func event(_ name: String, _ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: name, handler: handler)
    }

    static func onClick(_ handler: @escaping () -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "click") { _ in handler() }
    }

    static func onClick(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "click", handler: handler)
    }

    static func onInput(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "input", handler: handler)
    }

    static func onChange(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "change", handler: handler)
    }

    static func onSubmit(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "submit", handler: handler)
    }

    static func onKeyDown(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "keydown", handler: handler)
    }

    static func onKeyUp(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "keyup", handler: handler)
    }

    static func onFocus(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "focus", handler: handler)
    }

    static func onBlur(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "blur", handler: handler)
    }

    static func onMouseDown(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "mousedown", handler: handler)
    }

    static func onMouseUp(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "mouseup", handler: handler)
    }

    static func onMouseMove(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "mousemove", handler: handler)
    }

    static func onMouseEnter(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "mouseenter", handler: handler)
    }

    static func onMouseLeave(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "mouseleave", handler: handler)
    }

    static func onPointerDown(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "pointerdown", handler: handler)
    }

    static func onPointerUp(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "pointerup", handler: handler)
    }

    static func onPointerMove(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "pointermove", handler: handler)
    }

    static func onPointerEnter(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "pointerenter", handler: handler)
    }

    static func onPointerLeave(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "pointerleave", handler: handler)
    }

    static func onDragStart(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "dragstart", handler: handler)
    }

    static func onDragOver(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "dragover", handler: handler)
    }

    static func onDrop(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "drop", handler: handler)
    }

    static func onReset(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "reset", handler: handler)
    }

    static func onInvalid(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "invalid", handler: handler)
    }

    static func onLoad(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "load", handler: handler)
    }

    static func onError(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "error", handler: handler)
    }

    static func onScroll(_ handler: @escaping (DOMEvent) -> Void) -> HTMLAttribute {
        HTMLAttribute(eventName: "scroll", handler: handler)
    }
}
