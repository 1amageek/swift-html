import SwiftHTML
import Testing

@Suite
struct SwiftHTMLActionTests {
    @Test
    func actionProvidesDefaultRepresentableImplementation() {
        let action = Action.post(
            "/counter",
            fields: [
                ActionField("delta", 1),
                ActionField("source", "button"),
            ]
        )

        #expect(action.path == "/counter")
        #expect(action.method == .post)
        #expect(action.fields == [
            ActionField("delta", "1"),
            ActionField("source", "button"),
        ])
    }
}
