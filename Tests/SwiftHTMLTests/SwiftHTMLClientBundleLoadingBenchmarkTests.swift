import Foundation
import SwiftHTML
import Testing

@Suite(.serialized)
struct SwiftHTMLClientBundleLoadingBenchmarkTests {
    @Test(.timeLimit(.minutes(1)))
    func resolvesLargeManifestIncrementallyWithinBudget() throws {
        guard Self.benchmarksEnabled else {
            return
        }

        let componentCount = 20_000
        let manifest = largeManifest(componentCount: componentCount)
        let resolver = try timed("loading resolver index \(componentCount)", limit: .seconds(2)) {
            ClientBundleLoadResolver(manifest: manifest)
        }
        let stagedPlans = try timed("loading resolver staged \(componentCount)", limit: .seconds(2)) {
            try resolver.stagedPlans()
        }
        let incrementalPlans = try timed("loading resolver incremental \(componentCount)", limit: .seconds(2)) {
            try resolver.incrementalStagedPlans()
        }
        let incrementalPlansIncludingManual = try timed("loading resolver incremental manual \(componentCount)", limit: .seconds(2)) {
            try resolver.incrementalStagedPlans(includeManual: true)
        }

        let incrementalBundleIDs = incrementalPlans.flatMap(\.bundleIDs)
        let incrementalBundleIDsIncludingManual = incrementalPlansIncludingManual.flatMap(\.bundleIDs)

        #expect(stagedPlans.count == ClientLoadPolicy.allCases.count)
        #expect(incrementalPlans.count == ClientLoadPolicy.allCases.count - 1)
        #expect(incrementalPlans.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle])
        #expect(incrementalPlansIncludingManual.count == ClientLoadPolicy.allCases.count)
        #expect(incrementalBundleIDs.count == Set(incrementalBundleIDs).count)
        #expect(incrementalBundleIDsIncludingManual.count == Set(incrementalBundleIDsIncludingManual).count)
        #expect(incrementalPlans[0].bundleIDs.prefix(3) == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            ClientBundleID("route:initial"),
        ])
        #expect(incrementalPlans[1].bundleIDs.allSatisfy { id in
            id.rawValue.hasPrefix("component:")
        })
        #expect(manifest.components.count == componentCount)
    }

    @Test(.timeLimit(.minutes(1)))
    func plansLargeSymbolGraphAndResolvesLoadingWithinBudget() throws {
        guard Self.benchmarksEnabled else {
            return
        }

        let componentCount = 3_000
        let graph = largeSymbolGraph(componentCount: componentCount)
        let manifest = try timed("split planner graph \(componentCount)", limit: .seconds(10)) {
            ClientBundlePlanner().plan(graph)
        }
        let resolver = ClientBundleLoadResolver(manifest: manifest)
        let incrementalPlans = try timed("split loader planned graph \(componentCount)", limit: .seconds(2)) {
            try resolver.incrementalStagedPlans()
        }

        #expect(manifest.components.count == componentCount)
        #expect(manifest.bundle(ClientBundleID("runtime")) != nil)
        #expect(manifest.bundle(ClientBundleID("shared")) != nil)
        #expect(!incrementalPlans.flatMap(\.bundleIDs).isEmpty)
    }

    private static var benchmarksEnabled: Bool {
        #if SWIFTHTML_ENABLE_LOADING_BENCHMARKS
        true
        #else
        ProcessInfo.processInfo.environment["SWIFTHTML_RUN_LOADING_BENCHMARKS"] == "1"
        #endif
    }

    private func timed<Result>(
        _ label: String,
        limit: Duration,
        operation: () throws -> Result
    ) throws -> Result {
        let clock = ContinuousClock()
        let start = clock.now
        let result = try operation()
        let elapsed = start.duration(to: clock.now)
        print("\(label): \(elapsed)")
        #expect(elapsed < limit)
        return result
    }

    private func largeManifest(componentCount: Int) -> ClientBundleManifest {
        var bundles: [ClientBundleRecord] = [
            ClientBundleRecord(
                id: ClientBundleID("runtime"),
                kind: .runtime,
                symbols: [symbolID("runtime")],
                estimatedByteSize: 1_000
            ),
            ClientBundleRecord(
                id: ClientBundleID("shared"),
                kind: .shared,
                symbols: [symbolID("shared.model")],
                dependencies: [ClientBundleID("runtime")],
                estimatedByteSize: 8_000
            ),
        ]
        var components: [ClientComponentAsset] = []
        var eagerComponentIDs: [ComponentID] = []

        for index in 0..<componentCount {
            let componentID = ComponentID("component-\(index)")
            let policy = loadPolicy(for: index)
            let bundleID = policy == .eager
                ? ClientBundleID("route:initial")
                : ClientBundleID("component:\(index)")

            components.append(ClientComponentAsset(
                componentID: componentID,
                typeName: "BenchmarkComponent\(index)",
                bundleID: bundleID,
                loadPolicy: policy,
                entrySymbols: [symbolID("component.\(index).entry")]
            ))

            if policy == .eager {
                eagerComponentIDs.append(componentID)
            } else {
                bundles.append(ClientBundleRecord(
                    id: bundleID,
                    kind: .component,
                    symbols: [
                        symbolID("component.\(index).entry"),
                        symbolID("component.\(index).view"),
                    ],
                    dependencies: [
                        ClientBundleID("runtime"),
                        ClientBundleID("shared"),
                    ],
                    components: [componentID],
                    loadPolicy: policy,
                    estimatedByteSize: 2_000
                ))
            }
        }

        bundles.append(ClientBundleRecord(
            id: ClientBundleID("route:initial"),
            kind: .route,
            symbols: [
                symbolID("route.entry"),
                symbolID("route.view"),
            ],
            dependencies: [
                ClientBundleID("runtime"),
                ClientBundleID("shared"),
            ],
            components: eagerComponentIDs,
            estimatedByteSize: 4_000
        ))

        return ClientBundleManifest(
            runtimeBundleID: ClientBundleID("runtime"),
            bundles: bundles,
            components: components
        )
    }

    private func largeSymbolGraph(componentCount: Int) -> ClientSymbolGraph {
        var symbols: [ClientSymbolRecord] = [
            ClientSymbolRecord(id: symbolID("runtime"), estimatedByteSize: 1_000),
            ClientSymbolRecord(id: symbolID("shared.model"), estimatedByteSize: 8_000),
        ]
        var dependencies: [ClientSymbolDependency] = []
        var components: [ClientComponentEntrypoint] = []

        for index in 0..<componentCount {
            let entry = symbolID("component.\(index).entry")
            let view = symbolID("component.\(index).view")
            let helper = symbolID("component.\(index).helper")
            symbols.append(ClientSymbolRecord(id: entry, estimatedByteSize: 400))
            symbols.append(ClientSymbolRecord(id: view, estimatedByteSize: 500))
            symbols.append(ClientSymbolRecord(id: helper, estimatedByteSize: 100))
            dependencies.append(ClientSymbolDependency(from: entry, to: view))
            dependencies.append(ClientSymbolDependency(from: view, to: helper))
            if index.isMultiple(of: 2) {
                dependencies.append(ClientSymbolDependency(from: entry, to: symbolID("shared.model")))
            }

            components.append(ClientComponentEntrypoint(
                componentID: ComponentID("component-\(index)"),
                typeName: "BenchmarkComponent\(index)",
                entrySymbols: [entry],
                loadPolicy: loadPolicy(for: index)
            ))
        }

        return ClientSymbolGraph(
            symbols: symbols,
            dependencies: dependencies,
            components: components,
            runtimeSymbols: [symbolID("runtime")]
        )
    }

    private func loadPolicy(for index: Int) -> ClientLoadPolicy {
        switch index % 5 {
        case 0:
            .eager
        case 1:
            .visible
        case 2:
            .interaction
        case 3:
            .idle
        default:
            .manual
        }
    }

    private func symbolID(_ value: String) -> ClientSymbolID {
        ClientSymbolID(value)
    }
}
