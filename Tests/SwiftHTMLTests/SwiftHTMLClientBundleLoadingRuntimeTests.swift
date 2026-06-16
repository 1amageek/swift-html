import SwiftHTML
import Testing

@Suite
struct SwiftHTMLClientBundleLoadingRuntimeTests {
    @Test
    func runtimeSchedulesCompleteClosuresWithoutDuplicateLoading() throws {
        var runtime = ClientBundleLoadingRuntime(manifest: manifest())

        let initial = try runtime.scheduleInitial()
        let visible = try runtime.schedule(loadPolicy: .visible)

        #expect(initial.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            ClientBundleID("route:initial"),
        ])
        #expect(initial.missingAssetBundleIDs.isEmpty)
        #expect(visible.bundleIDs == [ClientBundleID("component:visible")])
        #expect(visible.skippedBundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
        ])
        #expect(runtime.loadingBundleIDs == [
            ClientBundleID("component:visible"),
            ClientBundleID("route:initial"),
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
        ])

        runtime.complete(initial)

        #expect(runtime.loadedBundleIDs == [
            ClientBundleID("route:initial"),
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
        ])
    }

    @Test
    func manualBundlesRequireExplicitScheduling() throws {
        var runtime = ClientBundleLoadingRuntime(manifest: manifest())

        let automaticBatches = try runtime.scheduleAutomaticStages()
        let automaticBundleIDs = automaticBatches.flatMap(\.bundleIDs)

        #expect(!automaticBundleIDs.contains(ClientBundleID("component:manual")))

        let manual = try runtime.schedule(loadPolicy: .manual)

        #expect(manual.bundleIDs == [ClientBundleID("component:manual")])
        #expect(manual.skippedBundleIDs == [ClientBundleID("runtime")])
    }

    @Test
    func componentSchedulingCanLeadInitialRouteLoading() throws {
        var runtime = ClientBundleLoadingRuntime(manifest: manifest())

        let visible = try runtime.schedule(componentID: ComponentID("visible"))

        #expect(visible.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            ClientBundleID("component:visible"),
        ])

        runtime.complete(visible)

        let initial = try runtime.scheduleInitial()

        #expect(initial.bundleIDs == [ClientBundleID("route:initial")])
        #expect(initial.skippedBundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
        ])
    }

    private func manifest() -> ClientBundleManifest {
        ClientBundleManifest(
            runtimeBundleID: ClientBundleID("runtime"),
            bundles: [
                bundle("runtime", kind: .runtime, symbols: ["runtime"]),
                bundle(
                    "shared",
                    kind: .shared,
                    symbols: ["shared"],
                    dependencies: ["runtime"]
                ),
                bundle(
                    "route:initial",
                    kind: .route,
                    symbols: ["hero"],
                    dependencies: ["runtime", "shared"],
                    components: ["hero"]
                ),
                bundle(
                    "component:visible",
                    kind: .component,
                    symbols: ["visible"],
                    dependencies: ["runtime", "shared"],
                    components: ["visible"],
                    loadPolicy: .visible
                ),
                bundle(
                    "component:manual",
                    kind: .component,
                    symbols: ["manual"],
                    dependencies: ["runtime"],
                    components: ["manual"],
                    loadPolicy: .manual
                ),
            ],
            components: [
                component("hero", bundleID: "route:initial", loadPolicy: .eager),
                component("visible", bundleID: "component:visible", loadPolicy: .visible),
                component("manual", bundleID: "component:manual", loadPolicy: .manual),
            ]
        )
    }

    private func bundle(
        _ id: String,
        kind: ClientBundleKind,
        symbols: [String],
        dependencies: [String] = [],
        components: [String] = [],
        loadPolicy: ClientLoadPolicy = .eager
    ) -> ClientBundleRecord {
        let bundleID = ClientBundleID(id)
        let assetPath = "/assets/\(id.replacingOccurrences(of: ":", with: "-")).wasm"
        let asset = WasmAsset(
            path: assetPath,
            contentHash: "hash-\(id)",
            byteSize: 1_024
        )
        let symbolIDs = symbols.map { value in
            ClientSymbolID(value)
        }
        let dependencyIDs = dependencies.map { value in
            ClientBundleID(value)
        }
        let componentIDs = components.map { value in
            ComponentID(value)
        }
        return ClientBundleRecord(
            id: bundleID,
            kind: kind,
            asset: asset,
            symbols: symbolIDs,
            dependencies: dependencyIDs,
            components: componentIDs,
            loadPolicy: loadPolicy,
            estimatedByteSize: 1_024
        )
    }

    private func component(
        _ id: String,
        bundleID: String,
        loadPolicy: ClientLoadPolicy
    ) -> ClientComponentAsset {
        ClientComponentAsset(
            componentID: ComponentID(id),
            typeName: "Test\(id)",
            bundleID: ClientBundleID(bundleID),
            loadPolicy: loadPolicy,
            entrySymbols: [ClientSymbolID(id)]
        )
    }
}
