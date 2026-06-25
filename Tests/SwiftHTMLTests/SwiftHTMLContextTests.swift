import SwiftHTML
import Testing

private struct AuthContext: ContextKey, ClientEnvironmentKey {
    static let defaultValue = AuthSession.guest
}

private struct AuthSession: Codable, Sendable, Equatable {
    let userID: String?
    let role: String

    static let guest = AuthSession(userID: nil, role: "guest")
    static let admin = AuthSession(userID: "user-1", role: "admin")
    static let member = AuthSession(userID: "user-2", role: "member")
}

private extension EnvironmentValues {
    var auth: AuthSession {
        get { self[AuthContext.self] }
        set { self[AuthContext.self] = newValue }
    }
}

private struct AuthStatus: ClientComponent, Sendable {
    @Context(AuthContext.self) private var auth: AuthSession

    @HTMLBuilder
    var body: some HTML {
        span(.class("auth-status")) {
            auth.role
        }
    }
}

private struct AuthStatefulPanel: ClientComponent, Sendable {
    @Context(AuthContext.self) private var auth: AuthSession
    @State private var taps = 0

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {
            taps += 1
        }) {
            "\(auth.role): \(taps)"
        }
    }
}

@Suite
struct SwiftHTMLContextTests {
    @Test
    func contextReadsDefaultValueFromEnvironment() {
        let rendered = AuthStatus().render()

        #expect(rendered.contains("<span class=\"auth-status\">guest</span>"))
    }

    @Test
    func environmentModifierOverridesScopedContextValue() {
        let rendered = div {
            AuthStatus()
            Group {
                AuthStatus()
            }
            .environment(\.auth, .admin)
            AuthStatus()
        }
        .render()

        #expect(rendered.components(separatedBy: "<span class=\"auth-status\">guest</span>").count - 1 == 2)
        #expect(rendered.components(separatedBy: "<span class=\"auth-status\">admin</span>").count - 1 == 1)
    }

    @Test
    func environmentModifierUsesContextKey() {
        let rendered = div {
            AuthStatus()
        }
        .environment(\.auth, .member)
        .render()

        #expect(rendered.contains("<span class=\"auth-status\">member</span>"))
    }

    @Test
    func environmentModifierWithContextKeyDoesNotCreateHydrationBoundary() {
        let artifact = Group {
            AuthStatus()
        }
        .environment(\.auth, .admin)
        .renderArtifact()

        #expect(artifact.hydration.components.count == 1)
        #expect(artifact.hydration.components[0].typeName.hasSuffix(".AuthStatus"))
        #expect(artifact.hydration.components[0].environmentSnapshot.values.count == 1)
        #expect(artifact.diagnostics.isEmpty)
    }

    @Test
    func contextAndStateShareComponentIdentity() throws {
        let store = StateStore()
        let first = Group {
            AuthStatefulPanel()
        }
        .environment(\.auth, .admin)
        .renderArtifact(stateStore: store)

        let component = try #require(first.hydration.components.first)
        let handler = try #require(first.clientHandlers.handlers.first)

        #expect(first.html.contains("admin: 0"))
        #expect(handler.componentID == component.id)

        handler.invoke()

        let second = Group {
            AuthStatefulPanel()
        }
        .environment(\.auth, .admin)
        .renderArtifact(stateStore: store)

        #expect(second.hydration.components.first?.id == component.id)
        #expect(second.html.contains("admin: 1"))
    }
}
