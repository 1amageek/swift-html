import SwiftHTML
import Testing

@Suite
struct SwiftHTMLClientBundlePlannerTests {
    @Test
    func partitionsSymbolGraphIntoRuntimeSharedRouteAndComponentBundles() throws {
        let componentA = ComponentID("component-a")
        let componentB = ComponentID("component-b")
        let graph = ClientSymbolGraph(
            symbols: [
                symbol("runtime", size: 10),
                symbol("a.entry", size: 11),
                symbol("a.view", size: 12),
                symbol("b.entry", size: 13),
                symbol("b.view", size: 14),
                symbol("shared.format", size: 30),
                symbol("shared.helper", size: 5),
                symbol("cycle.one", size: 7),
                symbol("cycle.two", size: 8),
            ],
            dependencies: [
                dependency("a.entry", "a.view"),
                dependency("a.entry", "shared.format"),
                dependency("a.entry", "cycle.one"),
                dependency("b.entry", "b.view"),
                dependency("b.entry", "shared.format"),
                dependency("shared.format", "shared.helper"),
                dependency("cycle.one", "cycle.two"),
                dependency("cycle.two", "cycle.one"),
            ],
            components: [
                ClientComponentEntrypoint(
                    componentID: componentA,
                    typeName: "DashboardCounter",
                    entrySymbols: [id("a.entry")],
                    loadPolicy: .eager
                ),
                ClientComponentEntrypoint(
                    componentID: componentB,
                    typeName: "ActivityPanel",
                    entrySymbols: [id("b.entry")],
                    loadPolicy: .visible
                ),
            ],
            runtimeSymbols: [id("runtime")]
        )

        let manifest = ClientBundlePlanner().plan(graph)
        let runtime = try #require(manifest.bundle(ClientBundleID("runtime")))
        let shared = try #require(manifest.bundle(ClientBundleID("shared")))
        let route = try #require(manifest.bundle(ClientBundleID("route:initial")))
        let componentAssetA = try #require(manifest.component(componentA))
        let componentAssetB = try #require(manifest.component(componentB))
        let componentBundleB = try #require(manifest.bundle(componentAssetB.bundleID))

        #expect(runtime.kind == .runtime)
        #expect(runtime.symbols == [id("runtime")])
        #expect(runtime.dependencies.isEmpty)

        #expect(shared.kind == .shared)
        #expect(shared.symbols == [id("shared.format"), id("shared.helper")])
        #expect(shared.estimatedByteSize == 35)
        #expect(shared.dependencies == [ClientBundleID("runtime")])

        #expect(route.kind == .route)
        #expect(route.symbols == [id("a.entry"), id("a.view"), id("cycle.one"), id("cycle.two")])
        #expect(route.components == [componentA])
        #expect(route.dependencies == [ClientBundleID("runtime"), ClientBundleID("shared")])

        #expect(componentAssetA.bundleID == ClientBundleID("route:initial"))
        #expect(componentAssetA.loadPolicy == .eager)
        #expect(componentAssetB.loadPolicy == .visible)
        #expect(componentBundleB.kind == .component)
        #expect(componentBundleB.loadPolicy == .visible)
        #expect(componentBundleB.symbols == [id("b.entry"), id("b.view")])
        #expect(componentBundleB.dependencies == [ClientBundleID("runtime"), ClientBundleID("shared")])

        let cycleBundleIDs = manifest.bundles.compactMap { bundle -> ClientBundleID? in
            bundle.symbols.contains(id("cycle.one")) || bundle.symbols.contains(id("cycle.two")) ? bundle.id : nil
        }
        #expect(cycleBundleIDs == [ClientBundleID("route:initial")])
    }

    @Test
    func attachesHydrationServerSlotsToPlannedComponentAssets() throws {
        let component = ComponentID("component-with-server-slot")
        let stateSlot = StateSlotRecord(
            id: StateSlotID("component-with-server-slot:state:Counter.swift:7:5"),
            componentID: component,
            valueType: "Swift.Int",
            source: StateSourceLocation(fileID: "Counter.swift", line: 7, column: 5)
        )
        let slot = ServerSlotRecord(
            id: ServerSlotID("slot-profile"),
            ownerComponentID: component,
            componentType: "ProfileServerSlot",
            path: "root/child:0",
            nodeID: HTMLNodeID(42)
        )
        let environmentSnapshot = ClientEnvironmentSnapshot(values: [
            ClientEnvironmentSnapshotValue(
                key: "theme",
                valueType: "Swift.String",
                encoding: "json",
                encodedValue: #""dark""#
            ),
        ])
        let hydration = HydrationManifest(components: [
            HydrationComponentRecord(
                id: component,
                typeName: "ProfileIsland",
                path: "root",
                nodeID: HTMLNodeID(1),
                stateSlots: [stateSlot],
                loadPolicy: .interaction,
                serverSlots: [slot],
                environmentSnapshot: environmentSnapshot
            ),
        ])
        let graph = ClientSymbolGraph(
            symbols: [
                symbol("profile.entry", size: 20),
            ],
            components: [
                ClientComponentEntrypoint(
                    componentID: component,
                    typeName: "ProfileIsland",
                    entrySymbols: [id("profile.entry")],
                    loadPolicy: .interaction
                ),
            ]
        )

        let manifest = ClientBundlePlanner().plan(hydration: hydration, symbolGraph: graph)
        let componentAsset = try #require(manifest.component(component))

        #expect(manifest.serverSlots == [slot])
        #expect(componentAsset.serverSlots == [ServerSlotID("slot-profile")])
        #expect(componentAsset.loadPolicy == .interaction)
        #expect(componentAsset.stateSchemaHash == StateSchema.hash([stateSlot]))
        #expect(componentAsset.environmentSchemaHash == environmentSnapshot.schemaHash)
        #expect(try #require(manifest.bundle(componentAsset.bundleID)).kind == .component)
    }

    @Test
    func loadPolicyControlsPrimaryBundleWithoutDuplicatingSharedSymbols() throws {
        let eager = ComponentID("eager")
        let idle = ComponentID("idle")
        let graph = ClientSymbolGraph(
            symbols: [
                symbol("eager.entry", size: 3),
                symbol("idle.entry", size: 4),
                symbol("shared.model", size: 50),
            ],
            dependencies: [
                dependency("eager.entry", "shared.model"),
                dependency("idle.entry", "shared.model"),
            ],
            components: [
                ClientComponentEntrypoint(
                    componentID: eager,
                    typeName: "HeroSearch",
                    entrySymbols: [id("eager.entry")],
                    loadPolicy: .eager
                ),
                ClientComponentEntrypoint(
                    componentID: idle,
                    typeName: "AnalyticsPanel",
                    entrySymbols: [id("idle.entry")],
                    loadPolicy: .idle
                ),
            ]
        )

        let manifest = ClientBundlePlanner().plan(graph)
        let shared = try #require(manifest.bundle(ClientBundleID("shared")))
        let eagerAsset = try #require(manifest.component(eager))
        let idleAsset = try #require(manifest.component(idle))
        let idleBundle = try #require(manifest.bundle(idleAsset.bundleID))

        #expect(shared.symbols == [id("shared.model")])
        #expect(eagerAsset.bundleID == ClientBundleID("route:initial"))
        #expect(idleAsset.bundleID != ClientBundleID("route:initial"))
        #expect(idleBundle.loadPolicy == .idle)
        #expect(idleBundle.symbols == [id("idle.entry")])
        #expect(!idleBundle.symbols.contains(id("shared.model")))
    }

    private func id(_ value: String) -> ClientSymbolID {
        ClientSymbolID(value)
    }

    private func symbol(_ value: String, size: Int) -> ClientSymbolRecord {
        ClientSymbolRecord(id: id(value), estimatedByteSize: size)
    }

    private func dependency(_ from: String, _ to: String) -> ClientSymbolDependency {
        ClientSymbolDependency(from: id(from), to: id(to))
    }
}
