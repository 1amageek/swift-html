import SwiftHTML
import Testing

private struct BoundaryClientKey: ClientEnvironmentKey {
    static let defaultValue = "client-default"
}

private struct BoundaryServerOnlyKey: EnvironmentKey {
    static let defaultValue = "server-default"
}

private struct BoundaryFailingClientEnvironmentValue: Codable, Sendable, CustomStringConvertible {
    init() {}

    init(from decoder: Decoder) throws {}

    func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue(
            "boundary",
            EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Boundary encoding failure"
            )
        )
    }

    var description: String {
        "boundary"
    }
}

private struct BoundaryFailingClientKey: ClientEnvironmentKey {
    static let defaultValue = BoundaryFailingClientEnvironmentValue()
}

private extension EnvironmentValues {
    var boundaryClientValue: String {
        get { self[BoundaryClientKey.self] }
        set { self[BoundaryClientKey.self] = newValue }
    }

    var boundaryServerOnlyValue: String {
        get { self[BoundaryServerOnlyKey.self] }
        set { self[BoundaryServerOnlyKey.self] = newValue }
    }

    var boundaryFailingClientValue: BoundaryFailingClientEnvironmentValue {
        get { self[BoundaryFailingClientKey.self] }
        set { self[BoundaryFailingClientKey.self] = newValue }
    }
}

private struct BoundaryServerPage: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        section {
            "server"
            BoundaryClientCounter()
        }
    }
}

private struct BoundaryClientCounter: ClientComponent {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            count += 1
        }) {
            "Count \(count)"
        }
    }
}

private struct BoundaryClientShell: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        div {
            BoundaryPlainLabel()
        }
    }
}

private struct BoundaryPlainLabel: Component {
    @HTMLBuilder
    var body: some HTML {
        span {
            "plain"
        }
    }
}

private struct BoundaryOuterClient: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        BoundaryServerSlot()
    }
}

private struct BoundaryServerSlot: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        article {
            "slot"
            BoundaryInnerClient()
        }
    }
}

private struct BoundaryInnerClient: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        span {
            "inner"
        }
    }
}

private struct BoundaryOuterClientWithServerText: ClientComponent {
    let text: String

    @HTMLBuilder
    var body: some HTML {
        BoundaryServerTextSlot(text: text)
    }
}

private struct BoundaryServerTextSlot: ServerComponent {
    let text: String

    @HTMLBuilder
    var body: some HTML {
        p {
            text
        }
    }
}

private struct BoundaryEnvironmentReader: ClientComponent {
    @Environment(\.boundaryClientValue) private var clientValue: String
    @Environment(\.boundaryServerOnlyValue) private var serverOnlyValue: String

    @HTMLBuilder
    var body: some HTML {
        div {
            span(.class("client")) {
                clientValue
            }
            span(.class("server")) {
                serverOnlyValue
            }
        }
    }
}

private struct BoundaryServerState: ServerComponent {
    @State private var count = 0

    @HTMLBuilder
    var body: some HTML {
        span {
            "Server count \(count)"
        }
    }
}

private struct BoundaryServerEvent: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {}) {
            "Invalid"
        }
    }
}

private struct BoundaryServerCapabilityReader: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        span {
            serverCapabilityText()
        }
    }

    private func serverCapabilityText() -> String {
        ServerCapabilityReadContext.record("@Server(\\.request)", valueType: String.self)
        return "client"
    }
}

private struct BoundaryFailingClientEnvironmentReader: ClientComponent {
    @Environment(\.boundaryFailingClientValue) private var value: BoundaryFailingClientEnvironmentValue

    @HTMLBuilder
    var body: some HTML {
        span {
            value.description
        }
    }
}

@Suite
struct SwiftHTMLServerClientBoundaryTests {
    @Test
    func serverComponentDoesNotCreateHydrationBoundaryForItself() throws {
        let artifact = BoundaryServerPage().renderArtifact()

        #expect(artifact.hydration.components.count == 1)
        #expect(artifact.hydration.components[0].typeName.hasSuffix(".BoundaryClientCounter"))
        #expect(!artifact.html.contains(".BoundaryServerPage"))
        #expect(artifact.diagnostics.isEmpty)
        try artifact.validateHydration()

        let handler = try #require(artifact.clientHandlers.handlers.first)
        #expect(handler.componentID == artifact.hydration.components[0].id)
    }

    @Test
    func clientOwnershipPropagatesToPlainNestedComponents() {
        let artifact = BoundaryClientShell().renderArtifact()
        let componentNames = artifact.hydration.components.map(\.typeName)

        #expect(componentNames.contains { $0.hasSuffix(".BoundaryClientShell") })
        #expect(componentNames.contains { $0.hasSuffix(".BoundaryPlainLabel") })
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func serverComponentInsideClientResetsOwnershipButNestedClientCanHydrate() throws {
        let artifact = BoundaryOuterClient().renderArtifact()
        let componentNames = artifact.hydration.components.map(\.typeName)
        let outer = try #require(artifact.hydration.components.first { component in
            component.typeName.hasSuffix(".BoundaryOuterClient")
        })
        let slot = try #require(outer.serverSlots.first)

        #expect(componentNames.contains { $0.hasSuffix(".BoundaryOuterClient") })
        #expect(!componentNames.contains { $0.hasSuffix(".BoundaryServerSlot") })
        #expect(componentNames.contains { $0.hasSuffix(".BoundaryInnerClient") })
        #expect(slot.ownerComponentID == outer.id)
        #expect(slot.componentType.hasSuffix(".BoundaryServerSlot"))
        #expect(artifact.html.contains("server-slot:\(slot.id.rawValue):begin"))
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func serverSlotIsOpaqueForClientDiffing() {
        let oldArtifact = BoundaryOuterClientWithServerText(text: "old").renderArtifact()
        let newArtifact = BoundaryOuterClientWithServerText(text: "new").renderArtifact()
        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(!patches.contains { patch in
            if case .updateText = patch.operation {
                return true
            }
            return false
        })
        #expect(!patches.contains { patch in
            if case .replaceSubtree = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func clientComponentSnapshotsClientEnvironmentAndReportsServerOnlyReads() throws {
        let artifact = BoundaryEnvironmentReader()
            .environment(\.boundaryClientValue, "client-value")
            .environment(\.boundaryServerOnlyValue, "server-secret")
            .renderArtifact()

        let component = try #require(artifact.hydration.components.first)

        #expect(component.environmentSnapshot.values.count == 1)
        #expect(component.environmentSnapshot.values[0].encodedValue == "\"client-value\"")
        #expect(component.environmentReads.contains { read in
            read.key.contains("BoundaryServerOnlyKey") && read.visibility == .serverOnly
        })
        let diagnostic = try #require(artifact.diagnostics.first { diagnostic in
            diagnostic.code == .serverOnlyEnvironmentInClientComponent
        })
        #expect(diagnostic.severity == .error)
        #expect(diagnostic.componentType?.hasSuffix(".BoundaryEnvironmentReader") == true)
        #expect(diagnostic.path == "root")
        #expect(diagnostic.hint?.contains("ClientEnvironmentKey") == true)
        #expect(artifact.formattedDiagnostics.contains("swift-html.hydration.server-only-environment-in-client-component"))
        #expect(artifact.formattedDiagnostics.contains("hint:"))

        do {
            try artifact.validateHydration()
            Issue.record("Expected hydration validation to fail")
        } catch let error as RenderDiagnosticError {
            #expect(error.diagnostics.map(\.code).contains(.serverOnlyEnvironmentInClientComponent))
            #expect(error.description.contains("server-only-environment"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func clientEnvironmentSnapshotEncodingFailureReportsDiagnostic() throws {
        let artifact = BoundaryFailingClientEnvironmentReader().renderArtifact()
        let component = try #require(artifact.hydration.components.first)
        let diagnostic = try #require(artifact.errors.first { diagnostic in
            diagnostic.code == .clientEnvironmentSnapshotEncodingFailed
        })

        #expect(component.environmentSnapshot.values.isEmpty)
        #expect(diagnostic.message.contains("BoundaryFailingClientKey"))
        #expect(diagnostic.message.contains("Boundary encoding failure"))

        do {
            try artifact.validateHydration()
            Issue.record("Expected client environment snapshot encoding failure to fail validation")
        } catch let error as RenderDiagnosticError {
            #expect(error.diagnostics.map(\.code).contains(.clientEnvironmentSnapshotEncodingFailed))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func stateOutsideClientComponentReportsDiagnostic() {
        let artifact = BoundaryServerState().renderArtifact()

        #expect(artifact.hydration.components.isEmpty)
        #expect(artifact.errors.contains { diagnostic in
            diagnostic.code == .stateOutsideClientComponent
                && diagnostic.message.contains("@State")
                && diagnostic.hint?.contains("ClientComponent") == true
        })
    }

    @Test
    func eventHandlerOutsideClientComponentReportsDiagnostic() throws {
        let artifact = BoundaryServerEvent().renderArtifact()
        let diagnostic = try #require(artifact.errors.first)

        #expect(diagnostic.code == .eventHandlerOutsideClientComponent)
        #expect(diagnostic.componentType?.hasSuffix(".BoundaryServerEvent") == true)
        #expect(diagnostic.hint?.contains("ClientComponent") == true)
        #expect(artifact.clientHandlers.handlers.count == 1)
    }

    @Test
    func serverCapabilityInsideClientComponentReportsDiagnostic() throws {
        let artifact = BoundaryServerCapabilityReader().renderArtifact()
        let component = try #require(artifact.hydration.components.first)
        let read = try #require(component.serverCapabilityReads.first)
        let diagnostic = try #require(artifact.errors.first { diagnostic in
            diagnostic.code == .serverCapabilityInClientComponent
        })

        #expect(read.key == "@Server(\\.request)")
        #expect(read.valueType == "Swift.String")
        #expect(diagnostic.componentType?.hasSuffix(".BoundaryServerCapabilityReader") == true)
        #expect(diagnostic.message.contains("server capability"))
        #expect(diagnostic.hint?.contains("@Server") == true)

        do {
            try artifact.validateHydration()
            Issue.record("Expected server capability reads to fail validation")
        } catch let error as RenderDiagnosticError {
            #expect(error.diagnostics.map(\.code).contains(.serverCapabilityInClientComponent))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func productionRenderOptionsDoNotCaptureServerSideHandlerClosures() throws {
        let artifact = HTMLRenderer().render(BoundaryClientCounter(), options: .production)
        let handler = try #require(artifact.clientHandlers.handlers.first)

        #expect(handler.handler == nil)
        #expect(artifact.diagnostics.isEmpty)
        #expect(artifact.html.contains("data-event-click=\"h1\""))
    }
}
