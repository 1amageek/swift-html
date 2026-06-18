import SwiftHTML
import Testing

private struct DiffRow: Identifiable, Sendable {
    let id: Int
    let title: String
}

@Suite
struct SwiftHTMLDiffTests {
    @Test
    func producesNoPatchesForIdenticalGraphs() {
        let oldArtifact = HTMLRenderer().render(page(title: "Same", rows: [1, 2, 3]))
        let newArtifact = HTMLRenderer().render(page(title: "Same", rows: [1, 2, 3]))

        #expect(HTMLDiffer().diff(from: oldArtifact, to: newArtifact).isEmpty)
    }

    @Test
    func replacesDifferentElementKinds() {
        let oldArtifact = HTMLRenderer().render(div { "content" })
        let newArtifact = HTMLRenderer().render(span { "content" })

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.count == 1)
        #expect(patches.contains { patch in
            if case .replaceSubtree(node: _, html: let html) = patch.operation {
                return html == "<span>content</span>"
            }
            return false
        })
    }

    @Test
    func updatesTextWithoutReplacingParentElement() {
        let oldArtifact = HTMLRenderer().render(p { "old" })
        let newArtifact = HTMLRenderer().render(p { "new" })

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.count == 1)
        #expect(patches.contains { patch in
            if case .updateText(node: _, value: "new") = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func updatesAttributesWithoutReplacingElement() {
        let oldArtifact = HTMLRenderer().render(button(.type(ButtonType.button)) { "Save" })
        let newArtifact = HTMLRenderer().render(button(.type(ButtonType.submit), .disabled) { "Save" })

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.count == 1)
        #expect(patches.contains { patch in
            if case .updateAttributes(node: _, attributes: let attributes) = patch.operation {
                return attributes.map(\.name) == ["type", "disabled"]
            }
            return false
        })
    }

    @Test
    func emitsPropertyPatchesForPropertyBindings() {
        let oldArtifact = HTMLRenderer().render(input(.property("value", "old")))
        let newArtifact = HTMLRenderer().render(input(.property("value", "new")))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.contains { patch in
            if case .setProperty(node: _, name: "value", value: "new") = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func replacesRawHTMLInsideStyleElementWhenContentChanges() {
        let oldArtifact = HTMLRenderer().render(style { rawHTML("a{color:red}") })
        let newArtifact = HTMLRenderer().render(style { rawHTML("a{color:blue}") })

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        // The <style> element is unchanged; only its rawHTML child differs, so the
        // diff targets the rawHTML node with a single subtree replacement carrying
        // the new, unescaped CSS. The browser runtime resolves this rawHTML target
        // through its sole-child <style> parent.
        #expect(patches.count == 1)
        #expect(patches.contains { patch in
            if case .replaceSubtree(node: _, html: let html) = patch.operation {
                return html == "a{color:blue}"
            }
            return false
        })
    }

    @Test
    func updatesCommentNodesWhenValueChanges() {
        let oldArtifact = HTMLRenderer().render(comment("old"))
        let newArtifact = HTMLRenderer().render(comment("new"))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches == [
            HTMLPatch(.updateComment(node: oldArtifact.rootID, value: "new")),
        ])
    }

    @Test
    func insertsAndRemovesUnkeyedChildrenByPosition() {
        let oldArtifact = HTMLRenderer().render(unkeyedList(["one", "two", "three"]))
        let newArtifact = HTMLRenderer().render(unkeyedList(["one", "two"]))

        let removePatches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(removePatches.contains { patch in
            if case .remove(parent: _, index: 2, node: _) = patch.operation {
                return true
            }
            return false
        })

        let insertPatches = HTMLDiffer().diff(from: newArtifact, to: oldArtifact)

        #expect(insertPatches.contains { patch in
            if case .insertSubtree(parent: _, index: 2, html: let html) = patch.operation {
                return html == "<li>three</li>"
            }
            return false
        })
    }

    @Test
    func patchSubtreeHTMLPreservesHydrationMarkersWhenConfigured() {
        let options = HTMLRenderOptions.development.withBrowserHydrationMarkers()
        let oldArtifact = HTMLRenderer().render(unkeyedList(["one"]), options: options)
        let newArtifact = HTMLRenderer().render(unkeyedList(["one", "two"]), options: options)

        let patches = HTMLDiffer(renderOptions: options).diff(from: oldArtifact, to: newArtifact)

        #expect(patches.contains { patch in
            if case .insertSubtree(parent: _, index: _, html: let html) = patch.operation {
                return html.contains("<li data-node=\"")
                    && html.contains(">two</li>")
            }
            return false
        })
    }

    @Test
    func diffsKeyedChildrenByStableKey() {
        let oldArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 1, title: "One"),
            DiffRow(id: 2, title: "Two"),
            DiffRow(id: 3, title: "Three"),
        ]))
        let newArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 3, title: "Three"),
            DiffRow(id: 1, title: "One updated"),
            DiffRow(id: 4, title: "Four"),
        ]))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.contains { patch in
            if case .moveKeyed(parent: _, key: let key, to: 1) = patch.operation {
                return key.rawValue == "1"
            }
            return false
        })
        #expect(patches.contains { patch in
            if case .moveKeyed(parent: _, key: let key, to: 0) = patch.operation {
                return key.rawValue == "3"
            }
            return false
        })
        #expect(patches.contains { patch in
            if case .remove(parent: _, index: 1, node: _) = patch.operation {
                return true
            }
            return false
        })
        #expect(patches.contains { patch in
            if case .insertSubtree(parent: _, index: 2, html: let html) = patch.operation {
                return html == "<li>Four</li>"
            }
            return false
        })
        #expect(patches.contains { patch in
            if case .updateText(node: _, value: "One updated") = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func keyedReorderDoesNotEmitTextUpdatesForUnchangedRows() {
        let oldArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 1, title: "One"),
            DiffRow(id: 2, title: "Two"),
            DiffRow(id: 3, title: "Three"),
        ]))
        let newArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 3, title: "Three"),
            DiffRow(id: 2, title: "Two"),
            DiffRow(id: 1, title: "One"),
        ]))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)

        #expect(patches.contains { patch in
            if case .moveKeyed = patch.operation {
                return true
            }
            return false
        })
        #expect(!patches.contains { patch in
            if case .updateText = patch.operation {
                return true
            }
            return false
        })
    }

    @Test
    func keyedInsertionBeforeMovedChildrenAppliesToExpectedDOM() throws {
        let oldArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 1, title: "One"),
            DiffRow(id: 3, title: "Three"),
        ]))
        let newArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 2, title: "Two"),
            DiffRow(id: 3, title: "Three"),
            DiffRow(id: 1, title: "One"),
        ]))

        let patches = HTMLDiffer().diff(from: oldArtifact, to: newArtifact)
        let snapshot = oldArtifact.domSnapshot()
        let updated = try HTMLDOMPatchApplicator().apply(patches, to: snapshot)

        #expect(updated.html == newArtifact.html)
    }

    @Test
    func keyedRemovalsAreEmittedInDescendingIndexOrder() {
        let oldArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 1, title: "One"),
            DiffRow(id: 2, title: "Two"),
            DiffRow(id: 3, title: "Three"),
        ]))
        let newArtifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 3, title: "Three"),
        ]))

        let removals = HTMLDiffer().diff(from: oldArtifact, to: newArtifact).compactMap { patch -> Int? in
            if case .remove(parent: _, index: let index, node: _) = patch.operation {
                return index
            }
            return nil
        }

        #expect(removals == [1, 0])
    }

    @Test
    func duplicateForEachKeysProduceIdentityDiagnostic() throws {
        let artifact = HTMLRenderer().render(keyedList([
            DiffRow(id: 1, title: "One"),
            DiffRow(id: 1, title: "Duplicate"),
        ]))

        let diagnostic = try #require(artifact.errors.first { diagnostic in
            diagnostic.code == .duplicateKeyInForEach
        })

        #expect(diagnostic.message.contains("duplicate key '1'"))
        #expect(diagnostic.path == "child:0")
        #expect(diagnostic.hint?.contains("@State identity") == true)

        do {
            try artifact.validateHydration()
            Issue.record("Expected duplicate keys to fail validation")
        } catch let error as RenderDiagnosticError {
            #expect(error.diagnostics.map(\.code).contains(.duplicateKeyInForEach))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    private func page(title: String, rows: [Int]) -> some HTML {
        article {
            h1 { title }
            keyedList(rows.map { DiffRow(id: $0, title: "Row \($0)") })
        }
    }

    private func unkeyedList(_ values: [String]) -> some HTML {
        ul {
            for value in values {
                li {
                    value
                }
            }
        }
    }

    private func keyedList(_ rows: [DiffRow]) -> some HTML {
        ul {
            ForEach(rows) { row in
                li {
                    row.title
                }
            }
        }
    }
}
