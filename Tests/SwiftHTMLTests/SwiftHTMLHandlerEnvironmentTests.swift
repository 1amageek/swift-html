import SwiftHTML
import Testing

private struct SelectedEnvironment: EnvironmentKey {
    static let defaultValue = "Missing context"
}
private struct EnvironmentEventControl: ClientComponent {
    @Environment({ $0[SelectedEnvironment.self] }) private var selection
    @State private var result = "Initial"
    var content: some Component { button(.onClick { result = selection }) { result } }
}

@Suite
struct SwiftHTMLHandlerEnvironmentTests {
    @Test
    func handlersUseTheEnvironmentThatCreatedTheirComponent() throws {
        var environment = EnvironmentValues()
        environment[SelectedEnvironment.self] = "Selected context"
        let store = StateStore()
        let artifact = EnvironmentEventControl().renderArtifact(environment: environment, stateStore: store)
        let handler = try #require(artifact.clientHandlers.handlers.first)
        handler.invoke()
        #expect(EnvironmentEventControl().renderArtifact(environment: environment, stateStore: store).html.contains("Selected context"))
    }
}
