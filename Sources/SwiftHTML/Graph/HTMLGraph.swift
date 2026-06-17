import Foundation
import Observation

public struct HTMLNodeID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

struct HTMLStringID: Sendable, Hashable, Codable {
    let rawValue: Int

    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct ComponentID: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct HandlerID: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Key: Hashable, Sendable, Codable {
    public let rawValue: String
    public let identity: String

    public init<ID: Hashable & Sendable>(_ value: ID) {
        self.rawValue = String(describing: value)
        self.identity = "\(String(reflecting: ID.self)):\(rawValue)"
    }

    init(rawValue: String, identity: String) {
        self.rawValue = rawValue
        self.identity = identity
    }

    func disambiguated(occurrence: Int) -> Key {
        Key(rawValue: rawValue, identity: "\(identity)#duplicate:\(occurrence)")
    }
}

public struct NodeFingerprint: Hashable, Sendable, Codable {
    public let rawValue: UInt64

    public init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

struct HTMLGraph: Sendable {
    var nodes: [HTMLNodeRecord]
    var attributes: [HTMLAttributeRecord]
    var edges: [HTMLNodeID]
    var strings: [String]

    init(
        nodes: [HTMLNodeRecord] = [],
        attributes: [HTMLAttributeRecord] = [],
        edges: [HTMLNodeID] = [],
        strings: [String] = []
    ) {
        self.nodes = nodes
        self.attributes = attributes
        self.edges = edges
        self.strings = strings
    }
}

struct HTMLNodeRecord: Sendable {
    var kind: HTMLNodeKind
    var firstAttribute: Int
    var attributeCount: Int
    var firstChild: Int
    var childCount: Int
    var flags: HTMLNodeFlags
    var fingerprint: NodeFingerprint
    var key: Key?

    init(
        kind: HTMLNodeKind,
        firstAttribute: Int,
        attributeCount: Int,
        firstChild: Int,
        childCount: Int,
        flags: HTMLNodeFlags = [],
        fingerprint: NodeFingerprint = NodeFingerprint(0),
        key: Key? = nil
    ) {
        self.kind = kind
        self.firstAttribute = firstAttribute
        self.attributeCount = attributeCount
        self.firstChild = firstChild
        self.childCount = childCount
        self.flags = flags
        self.fingerprint = fingerprint
        self.key = key
    }
}

enum HTMLNodeKind: Sendable, Equatable {
    case document
    case doctype
    case element(HTMLStringID)
    case text(HTMLStringID)
    case rawHTML(HTMLStringID)
    case fragment
    case component(ComponentID)
    case serverSlot(ServerSlotID)
    case placeholder(HTMLStringID)
    case comment(HTMLStringID)
}

public struct HTMLNodeFlags: OptionSet, Sendable, Equatable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let void = HTMLNodeFlags(rawValue: 1 << 0)
}

public struct HTMLAttributeRecord: Sendable, Equatable, Codable {
    public var name: String
    public var value: String?
    public var kind: HTMLAttributeKind
    public var handlerID: HandlerID?
    public var eventName: String?

    public init(
        name: String,
        value: String?,
        kind: HTMLAttributeKind,
        handlerID: HandlerID? = nil,
        eventName: String? = nil
    ) {
        self.name = name
        self.value = value
        self.kind = kind
        self.handlerID = handlerID
        self.eventName = eventName
    }
}

public struct ClientHandlerManifest {
    public var handlers: [ClientHandlerRecord]

    public init(handlers: [ClientHandlerRecord] = []) {
        self.handlers = handlers
    }
}

public struct ClientHandlerRecord {
    public let id: HandlerID
    public let eventName: String
    public let componentID: ComponentID?
    private let eventHandler: DOMEventHandler?

    public var handler: ((DOMEvent) -> Void)? {
        guard let eventHandler else {
            return nil
        }

        return { event in
            eventHandler.invoke(with: event)
        }
    }

    public init(
        id: HandlerID,
        eventName: String,
        componentID: ComponentID? = nil,
        handler: DOMEventHandler? = nil
    ) {
        self.id = id
        self.eventName = eventName
        self.componentID = componentID
        self.eventHandler = handler
    }

    public init(
        id: HandlerID,
        eventName: String,
        componentID: ComponentID? = nil,
        handler: @escaping (DOMEvent) -> Void
    ) {
        self.init(
            id: id,
            eventName: eventName,
            componentID: componentID,
            handler: DOMEventHandler(handler)
        )
    }

    public func invoke(with event: DOMEvent = DOMEvent()) {
        eventHandler?.invoke(with: event)
    }
}

public enum RenderDiagnosticSeverity: Sendable, Equatable {
    case warning
    case error
}

public enum RenderDiagnosticCode: String, Sendable, Equatable {
    case stateOutsideClientComponent = "swift-html.hydration.state-outside-client-component"
    case eventHandlerOutsideClientComponent = "swift-html.hydration.event-handler-outside-client-component"
    case serverOnlyEnvironmentInClientComponent = "swift-html.hydration.server-only-environment-in-client-component"
    case serverCapabilityInClientComponent = "swift-html.hydration.server-capability-in-client-component"
    case runtimeOnlyEnvironmentInClientComponent = "swift-html.hydration.runtime-only-environment-in-client-component"
    case clientEnvironmentSnapshotEncodingFailed = "swift-html.hydration.client-environment-snapshot-encoding-failed"
    case duplicateKeyInForEach = "swift-html.identity.duplicate-key-in-for-each"
    case invalidElementName = "swift-html.security.invalid-element-name"
    case invalidAttributeName = "swift-html.security.invalid-attribute-name"
    case unsafeURLAttribute = "swift-html.security.unsafe-url-attribute"
}

public struct RenderDiagnostic: Sendable, Equatable {
    public let code: RenderDiagnosticCode
    public let severity: RenderDiagnosticSeverity
    public let message: String
    public let componentID: ComponentID?
    public let componentType: String?
    public let path: String?
    public let hint: String?

    public init(
        code: RenderDiagnosticCode,
        severity: RenderDiagnosticSeverity,
        message: String,
        componentID: ComponentID? = nil,
        componentType: String? = nil,
        path: String? = nil,
        hint: String? = nil
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.componentID = componentID
        self.componentType = componentType
        self.path = path
        self.hint = hint
    }

    public var formattedMessage: String {
        var output = "[\(severity.label)] \(code.rawValue): \(message)"
        if let componentType {
            output += " component=\(componentType)"
        }
        if let path {
            output += " path=\(path)"
        }
        if let componentID {
            output += " id=\(componentID.rawValue)"
        }
        if let hint {
            output += "\n  hint: \(hint)"
        }
        return output
    }
}

public extension RenderDiagnosticSeverity {
    var label: String {
        switch self {
        case .warning:
            "warning"
        case .error:
            "error"
        }
    }
}

public struct HydrationManifest: Sendable {
    public var components: [HydrationComponentRecord]

    public init(components: [HydrationComponentRecord] = []) {
        self.components = components
    }

    public var componentIDs: [ComponentID] {
        components.map(\.id)
    }
}

public struct HydrationComponentRecord: Sendable, Equatable {
    public let id: ComponentID
    public let typeName: String
    public let path: String
    public let nodeID: HTMLNodeID
    public let stateSlots: [StateSlotRecord]
    public let environmentReads: [EnvironmentReadRecord]
    public let serverCapabilityReads: [ServerCapabilityReadRecord]
    public let bundleID: ClientBundleID?
    public let loadPolicy: ClientLoadPolicy
    public let serverSlots: [ServerSlotRecord]
    public let environmentSnapshot: ClientEnvironmentSnapshot

    public init(
        id: ComponentID,
        typeName: String,
        path: String,
        nodeID: HTMLNodeID,
        stateSlots: [StateSlotRecord] = [],
        environmentReads: [EnvironmentReadRecord] = [],
        serverCapabilityReads: [ServerCapabilityReadRecord] = [],
        bundleID: ClientBundleID? = nil,
        loadPolicy: ClientLoadPolicy = .eager,
        serverSlots: [ServerSlotRecord] = [],
        environmentSnapshot: ClientEnvironmentSnapshot = ClientEnvironmentSnapshot()
    ) {
        self.id = id
        self.typeName = typeName
        self.path = path
        self.nodeID = nodeID
        self.stateSlots = stateSlots
        self.environmentReads = environmentReads
        self.serverCapabilityReads = serverCapabilityReads
        self.bundleID = bundleID
        self.loadPolicy = loadPolicy
        self.serverSlots = serverSlots
        self.environmentSnapshot = environmentSnapshot
    }
}

public struct RenderArtifact {
    public let html: String
    let graph: HTMLGraph
    public let rootID: HTMLNodeID
    public let hydration: HydrationManifest
    public let clientHandlers: ClientHandlerManifest
    public let diagnostics: [RenderDiagnostic]

    init(
        html: String,
        graph: HTMLGraph,
        rootID: HTMLNodeID,
        hydration: HydrationManifest = HydrationManifest(),
        clientHandlers: ClientHandlerManifest = ClientHandlerManifest(),
        diagnostics: [RenderDiagnostic] = []
    ) {
        self.html = html
        self.graph = graph
        self.rootID = rootID
        self.hydration = hydration
        self.clientHandlers = clientHandlers
        self.diagnostics = diagnostics
    }

    public var warnings: [RenderDiagnostic] {
        diagnostics.filter { $0.severity == .warning }
    }

    public var errors: [RenderDiagnostic] {
        diagnostics.filter { $0.severity == .error }
    }

    public var hasDiagnostics: Bool {
        !diagnostics.isEmpty
    }

    public var hasErrors: Bool {
        !errors.isEmpty
    }

    public var formattedDiagnostics: String {
        diagnostics.map(\.formattedMessage).joined(separator: "\n")
    }

    public var nodeCount: Int {
        graph.nodes.count
    }

    public var stringCount: Int {
        graph.strings.count
    }

    public var attributeRecords: [HTMLAttributeRecord] {
        graph.attributes
    }

    public var nodeKeys: [Key] {
        graph.nodes.compactMap(\.key)
    }

    public func domSnapshot() -> HTMLDOMSnapshot {
        HTMLDOMSnapshot(graph: graph, rootID: rootID)
    }

    public func validateHydration() throws {
        if !errors.isEmpty {
            throw RenderDiagnosticError(diagnostics: errors)
        }
    }
}

public struct RenderDiagnosticError: Error, Sendable, CustomStringConvertible {
    public let diagnostics: [RenderDiagnostic]

    public init(diagnostics: [RenderDiagnostic]) {
        self.diagnostics = diagnostics
    }

    public var description: String {
        diagnostics.map(\.formattedMessage).joined(separator: "\n")
    }
}

extension HTMLGraph {
    func node(_ id: HTMLNodeID) -> HTMLNodeRecord {
        nodes[id.rawValue]
    }

    func string(_ id: HTMLStringID) -> String {
        strings[id.rawValue]
    }

    func attributes(of id: HTMLNodeID) -> [HTMLAttributeRecord] {
        let node = node(id)
        let end = node.firstAttribute + node.attributeCount
        return Array(attributes[node.firstAttribute..<end])
    }

    func children(of id: HTMLNodeID) -> [HTMLNodeID] {
        let node = node(id)
        let end = node.firstChild + node.childCount
        return Array(edges[node.firstChild..<end])
    }
}

struct HTMLGraphBuilder {
    private(set) var graph: HTMLGraph
    var environment: EnvironmentValues
    private(set) var hydration = HydrationManifest()
    private(set) var clientHandlers = ClientHandlerManifest()
    private(set) var diagnostics: [RenderDiagnostic] = []
    let stateStore: StateStore
    let options: HTMLRenderOptions

    private var handlerCounter = 0
    private var stringIDs: [String: HTMLStringID] = [:]
    private var pathSegments: [String] = []
    private var clientOwnershipDepth = 0
    private var clientComponentStack: [ComponentID] = []
    private var serverSlotsByOwner: [ComponentID: [ServerSlotRecord]] = [:]

    init(
        environment: EnvironmentValues = EnvironmentValues(),
        stateStore: StateStore = StateStore(),
        options: HTMLRenderOptions = .development
    ) {
        self.graph = HTMLGraph()
        self.environment = environment
        self.stateStore = stateStore
        self.options = options
    }

    mutating func append(_ html: some HTML) -> HTMLNodeID {
        appendAny(html)
    }

    mutating func append(_ html: some HTML, key: Key) -> HTMLNodeID {
        let id = withPathSegment("key:\(key.identity)") { builder in
            builder.appendAny(html)
        }
        graph.nodes[id.rawValue].key = key
        graph.nodes[id.rawValue].fingerprint = fingerprint(
            kind: graph.nodes[id.rawValue].kind,
            attributes: attributes(for: graph.nodes[id.rawValue]),
            children: children(for: graph.nodes[id.rawValue]),
            key: key
        )
        return id
    }

    mutating func report(_ diagnostic: RenderDiagnostic) {
        guard options.recordsDiagnostics else {
            return
        }
        diagnostics.append(diagnostic)
    }

    func renderPath() -> String {
        currentPath()
    }

    mutating func appendAny(_ html: any HTML) -> HTMLNodeID {
        if let primitive = html as? any HTMLPrimitive {
            return primitive.buildNode(in: &self)
        }

        if let element = html as? any ElementRepresentable {
            return element.element.buildNode(in: &self)
        }

        if let component = html as? any Component {
            let typeName = String(reflecting: Swift.type(of: component))
            let path = currentPath()
            let componentID = makeComponentID(typeName: typeName, path: path)
            let isExplicitClientComponent = component is any ClientComponent
            let isServerComponent = component is any ServerComponent
            let isClientOwned = isExplicitClientComponent || (clientOwnershipDepth > 0 && !isServerComponent)
            let serverSlotOwner = isServerComponent && clientOwnershipDepth > 0 ? clientComponentStack.last : nil
            let loadPolicy = (component as? any ClientLoadPolicyProviding)?.clientLoadPolicy ?? ClientLoadPolicy.eager
            let componentEnvironment = options.componentEnvironmentOverrides[path] ?? environment
            let store = stateStore
            let stateContext = StateRenderContext(
                componentID: componentID,
                componentType: typeName,
                path: path,
                store: stateStore,
                isClientOwned: isClientOwned
            )
            let environmentRecorder = isClientOwned ? EnvironmentReadRecorder() : nil
            let serverCapabilityRecorder = isClientOwned ? ServerCapabilityReadRecorder() : nil
            let previousClientOwnershipDepth = clientOwnershipDepth
            let previousClientComponentStack = clientComponentStack
            if isClientOwned {
                clientOwnershipDepth += 1
                clientComponentStack.append(componentID)
            } else if isServerComponent {
                clientOwnershipDepth = 0
            }
            let previousEnvironment = environment
            environment = componentEnvironment

            let childID = ServerCapabilityReadContext.$current.withValue(serverCapabilityRecorder) {
                EnvironmentReadContext.$current.withValue(environmentRecorder) {
                    StateContext.$current.withValue(stateContext) {
                        EnvironmentContext.$current.withValue(componentEnvironment) {
                            withObservationTracking {
                                let body = component.body
                                return appendAny(body)
                            } onChange: {
                                store.markDirty(componentID)
                            }
                        }
                    }
                }
            }
            clientOwnershipDepth = previousClientOwnershipDepth
            clientComponentStack = previousClientComponentStack
            environment = previousEnvironment

            let stateSlots = stateContext.stateSlots()
            if !isClientOwned, !stateSlots.isEmpty {
                report(RenderDiagnostic(
                    code: .stateOutsideClientComponent,
                    severity: .error,
                    message: "\(typeName) uses @State outside a ClientComponent boundary",
                    componentID: componentID,
                    componentType: typeName,
                    path: path,
                    hint: "Conform this component or an owning wrapper to ClientComponent, or move state to a ClientComponent child."
                ))
            }

            guard isClientOwned else {
                if let serverSlotOwner {
                    return wrapServerSlot(
                        childID,
                        ownerComponentID: serverSlotOwner,
                        componentType: typeName,
                        path: path
                    )
                }
                return childID
            }

            let reads = environmentRecorder?.reads() ?? []
            for read in reads where read.visibility == .serverOnly {
                report(RenderDiagnostic(
                    code: .serverOnlyEnvironmentInClientComponent,
                    severity: .error,
                    message: "\(typeName) reads server-only environment value \(read.key)",
                    componentID: componentID,
                    componentType: typeName,
                    path: path,
                    hint: "Use ClientEnvironmentKey for public Codable values, pass a client-safe prop, or keep the read inside ServerComponent."
                ))
            }
            for read in reads where read.visibility == .runtimeOnly {
                report(RenderDiagnostic(
                    code: .runtimeOnlyEnvironmentInClientComponent,
                    severity: .warning,
                    message: "\(typeName) reads runtime-only environment value \(read.key)",
                    componentID: componentID,
                    componentType: typeName,
                    path: path,
                    hint: "Runtime-only values are not encoded into the hydration environment snapshot. Ensure the client runtime provides this value or replace it with a ClientEnvironmentKey/prop."
                ))
            }
            let snapshotErrors = environmentRecorder?.snapshotErrors() ?? []
            for error in snapshotErrors {
                report(RenderDiagnostic(
                    code: .clientEnvironmentSnapshotEncodingFailed,
                    severity: .error,
                    message: error.description,
                    componentID: componentID,
                    componentType: typeName,
                    path: path,
                    hint: "ClientEnvironmentKey values must encode successfully before they can be hydrated on the client."
                ))
            }
            let serverCapabilityReads = serverCapabilityRecorder?.reads() ?? []
            for read in serverCapabilityReads {
                report(RenderDiagnostic(
                    code: .serverCapabilityInClientComponent,
                    severity: .error,
                    message: "\(typeName) reads server capability \(read.key)",
                    componentID: componentID,
                    componentType: typeName,
                    path: path,
                    hint: "Read @Server only from ServerComponent, page load, route handlers, or server actions. Pass client-safe values into ClientComponent instead."
                ))
            }

            let nodeID = addNode(kind: .component(componentID), children: [childID])
            hydration.components.append(HydrationComponentRecord(
                id: componentID,
                typeName: typeName,
                path: path,
                nodeID: nodeID,
                stateSlots: stateSlots,
                environmentReads: reads,
                serverCapabilityReads: serverCapabilityReads,
                bundleID: nil,
                loadPolicy: loadPolicy,
                serverSlots: serverSlotsByOwner[componentID, default: []],
                environmentSnapshot: environmentRecorder?.snapshot() ?? ClientEnvironmentSnapshot()
            ))
            return nodeID
        }

        return addNode(kind: .fragment, children: [])
    }

    mutating func withEnvironment<Result>(
        _ environment: EnvironmentValues,
        operation: (inout HTMLGraphBuilder) -> Result
    ) -> Result {
        let previous = self.environment
        self.environment = environment
        let result = EnvironmentContext.$current.withValue(environment) {
            operation(&self)
        }
        self.environment = previous
        return result
    }

    mutating func withPathSegment<Result>(
        _ segment: String,
        operation: (inout HTMLGraphBuilder) -> Result
    ) -> Result {
        pathSegments.append(segment)
        let result = operation(&self)
        pathSegments.removeLast()
        return result
    }

    mutating func intern(_ value: String) -> HTMLStringID {
        if let id = stringIDs[value] {
            return id
        }

        graph.strings.append(value)
        let id = HTMLStringID(graph.strings.count - 1)
        stringIDs[value] = id
        return id
    }

    mutating func addNode(
        kind: HTMLNodeKind,
        attributes: [HTMLAttribute] = [],
        children: [HTMLNodeID],
        flags: HTMLNodeFlags = [],
        key: Key? = nil
    ) -> HTMLNodeID {
        let firstAttribute = graph.attributes.count
        var attributeCount = 0
        for attribute in attributes {
            guard let record = makeRecord(for: attribute) else {
                continue
            }
            graph.attributes.append(record)
            attributeCount += 1
        }

        let firstChild = graph.edges.count
        graph.edges.append(contentsOf: children)

        let id = HTMLNodeID(graph.nodes.count)
        graph.nodes.append(HTMLNodeRecord(
            kind: kind,
            firstAttribute: firstAttribute,
            attributeCount: attributeCount,
            firstChild: firstChild,
            childCount: children.count,
            flags: flags,
            fingerprint: fingerprint(kind: kind, attributes: attributes, children: children, key: key),
            key: key
        ))
        return id
    }

    mutating func addInvalidElement(name: String) -> HTMLNodeID {
        report(RenderDiagnostic(
            code: .invalidElementName,
            severity: .error,
            message: "Invalid HTML element name '\(name)'",
            path: currentPath(),
            hint: "Element names must not contain whitespace, control characters, quotes, '/', '>', or '='."
        ))
        return addNode(kind: .placeholder(intern("swift-html-invalid-element")), children: [])
    }

    private mutating func wrapServerSlot(
        _ childID: HTMLNodeID,
        ownerComponentID: ComponentID,
        componentType: String,
        path: String
    ) -> HTMLNodeID {
        let slotID = makeServerSlotID(componentType: componentType, path: path)
        let nodeID = addNode(kind: .serverSlot(slotID), children: [childID])
        serverSlotsByOwner[ownerComponentID, default: []].append(ServerSlotRecord(
            id: slotID,
            ownerComponentID: ownerComponentID,
            componentType: componentType,
            path: path,
            nodeID: nodeID
        ))
        return nodeID
    }

    private mutating func makeRecord(for attribute: HTMLAttribute) -> HTMLAttributeRecord? {
        if attribute.kind == .eventBinding, let eventName = attribute.eventName {
            guard Self.isValidEventName(eventName) else {
                report(RenderDiagnostic(
                    code: .invalidAttributeName,
                    severity: .error,
                    message: "Invalid event name '\(eventName)'",
                    componentID: StateContext.current?.componentID,
                    componentType: StateContext.current?.componentType,
                    path: StateContext.current?.path ?? currentPath(),
                    hint: "Event names must be valid HTML data attribute suffixes."
                ))
                return nil
            }

            handlerCounter += 1
            let id = HandlerID("h\(handlerCounter)")
            if StateContext.current?.isClientOwned != true {
                report(RenderDiagnostic(
                    code: .eventHandlerOutsideClientComponent,
                    severity: .error,
                    message: "Event handler '\(eventName)' is used outside a ClientComponent boundary",
                    componentID: StateContext.current?.componentID,
                    componentType: StateContext.current?.componentType,
                    path: StateContext.current?.path,
                    hint: "Conform the component that owns this event closure to ClientComponent."
                ))
            }
            clientHandlers.handlers.append(ClientHandlerRecord(
                id: id,
                eventName: eventName,
                componentID: StateContext.current?.componentID,
                handler: options.capturesClientHandlerClosures ? attribute.eventHandler : nil
            ))
            return HTMLAttributeRecord(
                name: "data-swift-event-\(eventName)",
                value: id.rawValue,
                kind: .eventBinding,
                handlerID: id,
                eventName: eventName
            )
        }

        guard Self.isValidHTMLName(attribute.name) else {
            report(RenderDiagnostic(
                code: .invalidAttributeName,
                severity: .error,
                message: "Invalid HTML attribute name '\(attribute.name)'",
                componentID: StateContext.current?.componentID,
                componentType: StateContext.current?.componentType,
                path: StateContext.current?.path ?? currentPath(),
                hint: "Attribute names must not contain whitespace, control characters, quotes, '/', '>', or '='."
            ))
            return nil
        }

        if Self.requiresSafeURL(attribute), let value = attribute.value, !Self.isSafeURLValue(value, for: attribute) {
            report(RenderDiagnostic(
                code: .unsafeURLAttribute,
                severity: .error,
                message: "Unsafe URL value for attribute '\(attribute.name)'",
                componentID: StateContext.current?.componentID,
                componentType: StateContext.current?.componentType,
                path: StateContext.current?.path ?? currentPath(),
                hint: "Use a relative URL or an allowed scheme such as http, https, mailto, or tel."
            ))
            return nil
        }

        return HTMLAttributeRecord(name: attribute.name, value: attribute.value, kind: attribute.kind)
    }

    private static func requiresSafeURL(_ attribute: HTMLAttribute) -> Bool {
        switch attribute.kind {
        case .url, .urlList:
            true
        default:
            isURLAttributeName(attribute.name)
        }
    }

    private static func isURLAttributeName(_ name: String) -> Bool {
        switch name.lowercased() {
        case "href",
             "src",
             "poster",
             "cite",
             "action",
             "formaction",
             "manifest",
             "itemid",
             "itemtype",
             "srcset",
             "imagesrcset",
             "ping":
            true
        default:
            false
        }
    }

    static func isValidHTMLName(_ name: String) -> Bool {
        guard !name.isEmpty else {
            return false
        }

        for scalar in name.unicodeScalars {
            if scalar.value <= 0x20 || scalar.value == 0x7F {
                return false
            }

            switch scalar {
            case "\"", "'", "/", ">", "=", "<":
                return false
            default:
                continue
            }
        }

        return true
    }

    private static func isValidEventName(_ name: String) -> Bool {
        isValidHTMLName("data-swift-event-\(name)")
    }

    private static func isSafeURLValue(_ value: String, for attribute: HTMLAttribute) -> Bool {
        if attribute.kind == .urlList || isURLListAttributeName(attribute.name) {
            return isSafeURLList(value, attributeName: attribute.name)
        }
        return isSafeURL(value)
    }

    private static func isURLListAttributeName(_ name: String) -> Bool {
        switch name.lowercased() {
        case "srcset", "imagesrcset", "ping":
            true
        default:
            false
        }
    }

    private static func isSafeURLList(_ value: String, attributeName: String) -> Bool {
        switch attributeName.lowercased() {
        case "ping":
            value
                .split(whereSeparator: { $0.isWhitespace })
                .allSatisfy { isSafeURL(String($0)) }
        case "srcset", "imagesrcset":
            value
                .split(separator: ",")
                .allSatisfy { candidate in
                    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = trimmed.split(whereSeparator: { $0.isWhitespace }).first else {
                        return true
                    }
                    return isSafeURL(String(url))
                }
        default:
            isSafeURL(value)
        }
    }

    private static func isSafeURL(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return true
        }

        var scheme = ""
        for scalar in trimmed.unicodeScalars {
            switch scalar {
            case ":", "/", "?", "#":
                if scalar == ":" {
                    return isAllowedURLScheme(scheme)
                }
                return true
            default:
                if scalar.value <= 0x20 || scalar.value == 0x7F {
                    return false
                }
                scheme.unicodeScalars.append(scalar)
            }
        }

        return true
    }

    private static func isAllowedURLScheme(_ scheme: String) -> Bool {
        switch scheme.lowercased() {
        case "http", "https", "mailto", "tel":
            true
        default:
            false
        }
    }

    private func currentPath() -> String {
        if pathSegments.isEmpty {
            return "root"
        }

        return pathSegments.joined(separator: "/")
    }

    private func makeComponentID(typeName: String, path: String) -> ComponentID {
        ComponentID("c\(stableHashHex("\(typeName)|\(path)"))")
    }

    private func makeServerSlotID(componentType: String, path: String) -> ServerSlotID {
        ServerSlotID("s\(stableHashHex("\(componentType)|\(path)"))")
    }

    private func stableHashHex(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    private func fingerprint(
        kind: HTMLNodeKind,
        attributes: [HTMLAttribute],
        children: [HTMLNodeID],
        key: Key?
    ) -> NodeFingerprint {
        var hasher = StableFingerprintHasher()
        combine(kind, into: &hasher)
        for attribute in attributes {
            hasher.combine(attribute.name)
            hasher.combine(attribute.value)
            hasher.combine(String(describing: attribute.kind))
        }
        for child in children {
            hasher.combine(graph.nodes[child.rawValue].fingerprint.rawValue)
        }
        hasher.combine(key?.identity)
        return NodeFingerprint(hasher.finalize())
    }

    private func combine(_ kind: HTMLNodeKind, into hasher: inout StableFingerprintHasher) {
        switch kind {
        case .document:
            hasher.combine("document")
        case .doctype:
            hasher.combine("doctype")
        case .element(let nameID):
            hasher.combine("element")
            hasher.combine(graph.strings[nameID.rawValue])
        case .text(let stringID):
            hasher.combine("text")
            hasher.combine(graph.strings[stringID.rawValue])
        case .rawHTML(let stringID):
            hasher.combine("rawHTML")
            hasher.combine(graph.strings[stringID.rawValue])
        case .fragment:
            hasher.combine("fragment")
        case .component(let componentID):
            hasher.combine("component")
            hasher.combine(componentID.rawValue)
        case .serverSlot(let slotID):
            hasher.combine("serverSlot")
            hasher.combine(slotID.rawValue)
        case .placeholder(let stringID):
            hasher.combine("placeholder")
            hasher.combine(graph.strings[stringID.rawValue])
        case .comment(let stringID):
            hasher.combine("comment")
            hasher.combine(graph.strings[stringID.rawValue])
        }
    }

    private func attributes(for node: HTMLNodeRecord) -> [HTMLAttribute] {
        let end = node.firstAttribute + node.attributeCount
        return graph.attributes[node.firstAttribute..<end].map {
            HTMLAttribute(name: $0.name, value: $0.value, kind: $0.kind)
        }
    }

    private func children(for node: HTMLNodeRecord) -> [HTMLNodeID] {
        let end = node.firstChild + node.childCount
        return Array(graph.edges[node.firstChild..<end])
    }
}

private struct StableFingerprintHasher {
    private var hash: UInt64 = 14_695_981_039_346_656_037

    mutating func combine(_ value: String?) {
        guard let value else {
            combine("<nil>")
            return
        }

        combine(value)
    }

    mutating func combine(_ value: String) {
        for byte in value.utf8 {
            combine(byte)
        }
        combine(UInt8(0xFF))
    }

    mutating func combine(_ value: UInt64) {
        var remaining = value
        for _ in 0..<8 {
            combine(UInt8(truncatingIfNeeded: remaining))
            remaining >>= 8
        }
        combine(UInt8(0xFE))
    }

    func finalize() -> UInt64 {
        hash
    }

    private mutating func combine(_ byte: UInt8) {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
}
