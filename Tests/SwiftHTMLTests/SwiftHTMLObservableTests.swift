import Foundation
import Observation
import Synchronization
import SwiftHTML
import Testing

@Observable
private final class ObservableBook: Identifiable {
    let id: UUID
    var title: String

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

private final class ObservableLibrary: Sendable {
    private let storage: Mutex<[ObservableBook]>

    init(books: sending [ObservableBook]) {
        self.storage = Mutex(books)
    }

    var books: [ObservableBook] {
        storage.withLock { storage in
            storage
        }
    }

    func updateFirstTitle(_ title: String) {
        storage.withLock { storage in
            storage[0].title = title
        }
    }
}

private struct ObservableLibraryPage: ClientComponent {
    @State private var library: ObservableLibrary

    init(library: ObservableLibrary = ObservableLibrary(
        books: [
            ObservableBook(title: "Initial Title"),
        ]
    )) {
        self._library = State(wrappedValue: library)
    }

    @HTMLBuilder
    var body: some HTML {
        ObservableLibraryView()
            .environment(library)
    }
}

private struct ObservableLibraryView: Component {
    @Environment(ObservableLibrary.self) private var library: ObservableLibrary?

    @HTMLBuilder
    var body: some HTML {
        section(.class("library")) {
            if let library {
                ForEach(library.books) { book in
                    ObservableBookRow(book: book)
                    ObservableBookEditor(book: book)
                }
            } else {
                span(.class("library-missing")) {
                    "Library unavailable"
                }
            }
        }
    }
}

private struct ObservableBookRow: Component {
    let book: ObservableBook

    @HTMLBuilder
    var body: some HTML {
        span(.class("book-title")) {
            book.title
        }
    }
}

private struct ObservableBookEditor: Component {
    @Bindable var book: ObservableBook

    @HTMLBuilder
    var body: some HTML {
        input(
            .type(InputType.text),
            .value($book.title)
        )
    }
}

private struct MissingObservableLibraryPage: ClientComponent {
    @HTMLBuilder
    var body: some HTML {
        ObservableLibraryView()
    }
}

@Suite
struct SwiftHTMLObservableTests {
    @Test
    func observableModelFlowsThroughStateAndTypeEnvironment() throws {
        let store = StateStore()
        let library = ObservableLibrary(
            books: [
                ObservableBook(title: "Initial Title"),
            ]
        )
        let first = ObservableLibraryPage(library: library).renderArtifact(stateStore: store)

        #expect(first.html.contains("<span class=\"book-title\">Initial Title</span>"))
        #expect(first.html.contains("value=\"Initial Title\""))

        library.updateFirstTitle("Observation Title")

        #expect(!store.dirtyComponents().isEmpty)

        let second = ObservableLibraryPage(library: library).renderArtifact(stateStore: store)

        #expect(second.html.contains("<span class=\"book-title\">Observation Title</span>"))
        #expect(second.html.contains("value=\"Observation Title\""))
        #expect(second.errors.isEmpty)
        #expect(second.warnings.contains { diagnostic in
            diagnostic.code == .runtimeOnlyEnvironmentInClientComponent
                && diagnostic.message.contains("runtime-only environment")
        })
    }

    @Test
    func missingTypeEnvironmentRendersWithoutTrapping() {
        let artifact = MissingObservableLibraryPage().renderArtifact()

        #expect(artifact.html.contains("<span class=\"library-missing\">Library unavailable</span>"))
        #expect(artifact.errors.isEmpty)
        #expect(artifact.warnings.contains { diagnostic in
            diagnostic.code == .runtimeOnlyEnvironmentInClientComponent
                && diagnostic.message.contains("runtime-only environment")
        })
    }
}
