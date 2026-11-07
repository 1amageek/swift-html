import SwiftHTML
import Synchronization
import Testing

private final class LifetimeJournal: Sendable {
    let values = Mutex<[String]>([])
    func append(_ value: String) { values.withLock { $0.append(value) } }
    var entries: [String] { values.withLock { $0 } }
}
private struct LifetimeJournalKey: EnvironmentKey {
    static let defaultValue = LifetimeJournal()
}
private struct LifetimeChild: ClientComponent {
    let name: String
    @Environment({ $0[LifetimeJournalKey.self] }) private var journal
    var content: some Component {
        div(.event("appear") { _ in journal.append("appear:" + name) },
            .event("disappear") { _ in journal.append("disappear:" + name) }) { name }
    }
}
private struct LifetimeList: ClientComponent {
    @State private var children = ["a", "b"]
    var content: some Component {
        div {
            button(.id("reorder"), .onClick { children.reverse() }) { "Reorder" }
            button(.id("remove"), .onClick { children.removeAll { $0 == "b" } }) { "Remove" }
            ForEach(children, id: { $0 }) { LifetimeChild(name: $0) }
        }
    }
}
private struct LifetimeState: ClientComponent {
    @State private var count = 0
    var content: some Component {
        div(.event("appear") { _ in count += 1 }, .event("disappear") { _ in count += 1 }) { "Count \(count)" }
    }
}

@Suite
struct SwiftHTMLClientLifetimeTests {
    @Test
    func structuralLifetimeSurvivesReorderingAndEndsRemovedChildrenOnce() throws {
        let journal = LifetimeJournal()
        var environment = EnvironmentValues(); environment[LifetimeJournalKey.self] = journal
        var session = try HydrationRuntimeSession(root: LifetimeList(), environment: environment)
        #expect(journal.entries.isEmpty)
        session.startLifetime(); session.startLifetime()
        #expect(journal.entries == ["appear:a", "appear:b"])
        try invoke("reorder", session: &session)
        #expect(journal.entries == ["appear:a", "appear:b"])
        try invoke("remove", session: &session)
        #expect(journal.entries == ["appear:a", "appear:b", "disappear:b"])
        session.endLifetime(); session.endLifetime()
        #expect(journal.entries == ["appear:a", "appear:b", "disappear:b", "disappear:a"])
    }

    @Test
    func callbackMutationsRemainPendingWithoutRepeatedAppearance() throws {
        var session = try HydrationRuntimeSession(root: LifetimeState())
        session.startLifetime()
        #expect(try session.flush().html.contains("Count 1"))
        #expect(try session.flush().html.contains("Count 1"))
        session.endLifetime()
        #expect(try session.flush().html.contains("Count 2"))
    }

    private func invoke(_ id: String, session: inout HydrationRuntimeSession<LifetimeList>) throws {
        let index = session.artifact.browserHydrationIndex()
        let node = try #require(index.nodes.first { $0.attributes.contains { $0.name == "id" && $0.value == id } })
        let handler = try #require(index.handlers.first { $0.nodeID == node.id && $0.eventName == "click" })
        _ = try session.invoke(handlerID: handler.handlerID)
    }
}
