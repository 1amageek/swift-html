import SwiftHTML
import Testing
import Foundation

private struct ExplicitClientBoundary: ClientComponent {
    static let componentIdentity: String? = "Qualification.Counter"
    @State(identity: "counter") private var count = 0
    var content: some Component { button(.onClick { count += 1 }) { "Count \(count)" } }
}

private struct RelocatedClientState: ClientComponent {
    static let componentIdentity: String? = "Qualification.RelocatedState"
    @State private var count: Int
    init(line: UInt) { _count = State(wrappedValue: 0, identity: "count", fileID: "Projection.swift", line: line, column: 1) }
    var content: some Component { button(.onClick { count += 1 }) { "Count \(count)" } }
}

@Suite
struct SwiftHTMLExplicitClientIdentityTests {
    @Test
    func explicitStateIdentitySurvivesSourceProjectionLineChanges() throws {
        let store = StateStore()
        let first = RelocatedClientState(line: 10).renderArtifact(stateStore: store)
        try #require(first.clientHandlers.handlers.first).invoke()
        let projected = RelocatedClientState(line: 99).renderArtifact(stateStore: store)
        #expect(projected.html.contains("Count 1"))
        #expect(first.hydration.components.first?.stateSlots.first?.id == projected.hydration.components.first?.stateSlots.first?.id)
    }

    @Test
    func explicitStateRestoresAfterSourceProjectionMovesItsDeclaration() throws {
        let original = StateStore()
        let first = RelocatedClientState(line: 10).renderArtifact(stateStore: original)
        try #require(first.clientHandlers.handlers.first).invoke()
        let updated = RelocatedClientState(line: 10).renderArtifact(stateStore: original)
        let snapshot = try original.snapshot(schemaHash: updated.hydration.stateSchemaHash)
        let restored = StateStore()
        restored.restore(snapshot)
        let projected = RelocatedClientState(line: 99).renderArtifact(stateStore: restored)
        #expect(projected.html.contains("Count 1"))
    }

    @Test
    func authoredIdentityNamesTheHydratedBoundary() throws {
        let store = StateStore()
        let artifact = ExplicitClientBoundary().renderArtifact(stateStore: store)
        let boundary = try #require(artifact.hydration.components.first { $0.typeName == "Qualification.Counter" })
        #expect(!boundary.stateSlots.isEmpty)
        #expect(boundary.stateSlots.first?.valueType == "counter")
        #expect(boundary.stateSlots.first?.source.fileID.hasSuffix("SwiftHTMLExplicitClientIdentityTests.swift") == true)
        let action = try #require(artifact.clientHandlers.handlers.first)
        action.invoke()
        let next = ExplicitClientBoundary().renderArtifact(stateStore: store)
        #expect(next.html.contains("Count 1"))
        #expect(next.hydration.components.first?.id == boundary.id)
    }

    @Test
    func textSnapshotRoundTripsControlsAndUnicodeThroughTheStandardDecoder() throws {
        let text = "quote\" slash\\ control\u{0000}\n 日本語 🎆 </script>"
        let value = ClientEnvironmentSnapshotValue.text(key: "public-text", value: text)
        #expect(value.valueType == "Swift.String")
        let decoded = try JSONDecoder().decode(String.self, from: Data(value.encodedValue.utf8))
        #expect(decoded == text)
    }
}
