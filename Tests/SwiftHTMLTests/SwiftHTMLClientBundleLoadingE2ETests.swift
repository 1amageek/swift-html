import SwiftHTML
import Testing

private struct LoadingE2EPage: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        main {
            LoadingHeroIsland()
            LoadingAnalyticsIsland()
            LoadingHelpIsland()
        }
    }
}

private struct LoadingDeferredPage: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        main {
            LoadingAnalyticsIsland()
            LoadingHelpIsland()
        }
    }
}

private struct LoadingHeroIsland: ClientComponent, ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy {
        .eager
    }

    @HTMLBuilder
    var body: some HTML {
        div(.class("hero")) {
            h1 {
                "Dashboard"
            }
            button(.type(ButtonType.button), .onClick {}) {
                "Refresh"
            }
            LoadingProfileServerSlot()
        }
    }
}

private struct LoadingProfileServerSlot: ServerComponent {
    @HTMLBuilder
    var body: some HTML {
        article(.class("profile-slot")) {
            p {
                "Server profile"
            }
            LoadingProfileActionsIsland()
        }
    }
}

private struct LoadingProfileActionsIsland: ClientComponent, ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy {
        .interaction
    }

    @HTMLBuilder
    var body: some HTML {
        button(.type(ButtonType.button), .onClick {}) {
            "Open profile"
        }
    }
}

private struct LoadingAnalyticsIsland: ClientComponent, ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy {
        .visible
    }

    @HTMLBuilder
    var body: some HTML {
        section(.class("analytics")) {
            "Analytics"
        }
    }
}

private struct LoadingHelpIsland: ClientComponent, ClientLoadPolicyProviding {
    var clientLoadPolicy: ClientLoadPolicy {
        .idle
    }

    @HTMLBuilder
    var body: some HTML {
        aside(.class("help")) {
            "Help"
        }
    }
}

@Suite
struct SwiftHTMLClientBundleLoadingE2ETests {
    @Test
    func renderHydrationManifestAndLoadResolutionStaySplitByPolicy() throws {
        let artifact = LoadingE2EPage().renderArtifact()
        try artifact.validateHydration()

        let hero = try component(named: "LoadingHeroIsland", in: artifact)
        let profile = try component(named: "LoadingProfileActionsIsland", in: artifact)
        let analytics = try component(named: "LoadingAnalyticsIsland", in: artifact)
        let help = try component(named: "LoadingHelpIsland", in: artifact)
        let serverSlot = try #require(hero.serverSlots.first)

        #expect(artifact.html.contains("server-slot:\(serverSlot.id.rawValue):begin"))
        #expect(profile.serverSlots.isEmpty)
        #expect(artifact.clientHandlers.handlers.count == 2)

        let manifest = ClientBundlePlanner().plan(
            hydration: artifact.hydration,
            symbolGraph: symbolGraph(
                hero: hero,
                profile: profile,
                analytics: analytics,
                help: help
            )
        )
        let resolver = ClientBundleLoadResolver(manifest: manifest)
        let heroAsset = try #require(manifest.component(hero.id))
        let profileAsset = try #require(manifest.component(profile.id))
        let analyticsAsset = try #require(manifest.component(analytics.id))
        let helpAsset = try #require(manifest.component(help.id))

        #expect(manifest.serverSlots == [serverSlot])
        #expect(heroAsset.serverSlots == [serverSlot.id])
        #expect(heroAsset.bundleID == ClientBundleID("route:initial"))

        let initial = try resolver.initialPlan()
        let visible = try resolver.plan(for: .visible)
        let interaction = try resolver.plan(for: .interaction)
        let idle = try resolver.plan(for: .idle)
        let manual = try resolver.plan(for: .manual)

        #expect(initial.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            ClientBundleID("route:initial"),
        ])
        #expect(initial.components.map(\.componentID) == [hero.id])
        #expect(!initial.bundleIDs.contains(profileAsset.bundleID))
        #expect(!initial.bundleIDs.contains(analyticsAsset.bundleID))
        #expect(!initial.bundleIDs.contains(helpAsset.bundleID))

        #expect(visible.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            analyticsAsset.bundleID,
        ])
        #expect(visible.components.map(\.componentID) == [analytics.id])

        #expect(interaction.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            profileAsset.bundleID,
        ])
        #expect(interaction.components.map(\.componentID) == [profile.id])

        #expect(idle.bundleIDs == [
            ClientBundleID("runtime"),
            helpAsset.bundleID,
        ])
        #expect(idle.components.map(\.componentID) == [help.id])

        #expect(manual.bundleIDs.isEmpty)
        #expect(manual.components.isEmpty)

        let profilePlan = try resolver.plan(for: profile.id)
        #expect(profilePlan.bundleIDs == interaction.bundleIDs)
        #expect(profilePlan.components.map(\.componentID) == [profile.id])

        let stagedPlans = try resolver.stagedPlans()
        #expect(stagedPlans.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle, .manual])

        let incrementalPlans = try resolver.incrementalStagedPlans()
        #expect(incrementalPlans.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle])
        #expect(incrementalPlans[0].bundleIDs == initial.bundleIDs)
        #expect(incrementalPlans[1].bundleIDs == [analyticsAsset.bundleID])
        #expect(incrementalPlans[2].bundleIDs == [profileAsset.bundleID])
        #expect(incrementalPlans[3].bundleIDs == [helpAsset.bundleID])

        let incrementalPlansIncludingManual = try resolver.incrementalStagedPlans(includeManual: true)
        #expect(incrementalPlansIncludingManual.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle, .manual])
        #expect(incrementalPlansIncludingManual[4].bundleIDs.isEmpty)
    }

    @Test
    func initialPlanKeepsOnlyRuntimeBootstrapWhenEveryClientComponentIsDeferred() throws {
        let artifact = LoadingDeferredPage().renderArtifact()
        try artifact.validateHydration()

        let analytics = try component(named: "LoadingAnalyticsIsland", in: artifact)
        let help = try component(named: "LoadingHelpIsland", in: artifact)
        let manifest = ClientBundlePlanner().plan(
            hydration: artifact.hydration,
            symbolGraph: deferredSymbolGraph(analytics: analytics, help: help)
        )
        let resolver = ClientBundleLoadResolver(manifest: manifest)
        let analyticsAsset = try #require(manifest.component(analytics.id))
        let helpAsset = try #require(manifest.component(help.id))

        let initial = try resolver.initialPlan()
        let visible = try resolver.plan(for: .visible)
        let idle = try resolver.plan(for: .idle)

        #expect(initial.bundleIDs == [ClientBundleID("runtime")])
        #expect(initial.components.isEmpty)
        #expect(!initial.bundleIDs.contains(ClientBundleID("shared")))
        #expect(!initial.bundleIDs.contains(analyticsAsset.bundleID))
        #expect(!initial.bundleIDs.contains(helpAsset.bundleID))

        #expect(visible.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            analyticsAsset.bundleID,
        ])
        #expect(idle.bundleIDs == [
            ClientBundleID("runtime"),
            ClientBundleID("shared"),
            helpAsset.bundleID,
        ])

        let incrementalPlans = try resolver.incrementalStagedPlans()
        #expect(incrementalPlans[0].bundleIDs == [ClientBundleID("runtime")])
        #expect(incrementalPlans[1].bundleIDs == [
            ClientBundleID("shared"),
            analyticsAsset.bundleID,
        ])
        #expect(incrementalPlans[3].bundleIDs == [helpAsset.bundleID])
    }

    @Test
    func manualBundlesStayOutOfAutomaticIncrementalStages() throws {
        let componentID = ComponentID("manual-component")
        let componentBundleID = ClientBundleID("component:manual")
        let manifest = ClientBundleManifest(
            runtimeBundleID: ClientBundleID("runtime"),
            bundles: [
                ClientBundleRecord(
                    id: ClientBundleID("runtime"),
                    kind: .runtime,
                    symbols: [id("runtime")]
                ),
                ClientBundleRecord(
                    id: componentBundleID,
                    kind: .component,
                    symbols: [id("manual.entry")],
                    dependencies: [ClientBundleID("runtime")],
                    components: [componentID],
                    loadPolicy: .manual
                ),
            ],
            components: [
                ClientComponentAsset(
                    componentID: componentID,
                    typeName: "ManualPanel",
                    bundleID: componentBundleID,
                    loadPolicy: .manual,
                    entrySymbols: [id("manual.entry")]
                ),
            ]
        )
        let resolver = ClientBundleLoadResolver(manifest: manifest)

        let automaticPlans = try resolver.incrementalStagedPlans()
        let explicitPlans = try resolver.incrementalStagedPlans(includeManual: true)
        let manualPlan = try resolver.plan(for: componentID)

        #expect(automaticPlans.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle])
        #expect(!automaticPlans.flatMap(\.bundleIDs).contains(componentBundleID))
        #expect(explicitPlans.map(\.loadPolicy) == [.eager, .visible, .interaction, .idle, .manual])
        #expect(explicitPlans[4].bundleIDs == [componentBundleID])
        #expect(manualPlan.bundleIDs == [ClientBundleID("runtime"), componentBundleID])
    }

    private func component(named suffix: String, in artifact: RenderArtifact) throws -> HydrationComponentRecord {
        try #require(artifact.hydration.components.first { component in
            component.typeName.hasSuffix(".\(suffix)")
        })
    }

    private func symbolGraph(
        hero: HydrationComponentRecord,
        profile: HydrationComponentRecord,
        analytics: HydrationComponentRecord,
        help: HydrationComponentRecord
    ) -> ClientSymbolGraph {
        ClientSymbolGraph(
            symbols: [
                symbol("runtime", size: 5),
                symbol("hero.entry", size: 10),
                symbol("hero.view", size: 11),
                symbol("profile.entry", size: 12),
                symbol("profile.view", size: 13),
                symbol("analytics.entry", size: 14),
                symbol("analytics.view", size: 15),
                symbol("help.entry", size: 16),
                symbol("help.view", size: 17),
                symbol("shared.model", size: 40),
            ],
            dependencies: [
                dependency("hero.entry", "hero.view"),
                dependency("hero.entry", "shared.model"),
                dependency("profile.entry", "profile.view"),
                dependency("profile.entry", "shared.model"),
                dependency("analytics.entry", "analytics.view"),
                dependency("analytics.entry", "shared.model"),
                dependency("help.entry", "help.view"),
            ],
            components: [
                entrypoint(hero, entry: "hero.entry"),
                entrypoint(profile, entry: "profile.entry"),
                entrypoint(analytics, entry: "analytics.entry"),
                entrypoint(help, entry: "help.entry"),
            ],
            runtimeSymbols: [id("runtime")]
        )
    }

    private func deferredSymbolGraph(
        analytics: HydrationComponentRecord,
        help: HydrationComponentRecord
    ) -> ClientSymbolGraph {
        ClientSymbolGraph(
            symbols: [
                symbol("runtime", size: 5),
                symbol("deferred.analytics.entry", size: 14),
                symbol("deferred.analytics.view", size: 15),
                symbol("deferred.help.entry", size: 16),
                symbol("deferred.help.view", size: 17),
                symbol("shared.model", size: 40),
            ],
            dependencies: [
                dependency("deferred.analytics.entry", "deferred.analytics.view"),
                dependency("deferred.analytics.entry", "shared.model"),
                dependency("deferred.help.entry", "deferred.help.view"),
                dependency("deferred.help.entry", "shared.model"),
            ],
            components: [
                entrypoint(analytics, entry: "deferred.analytics.entry"),
                entrypoint(help, entry: "deferred.help.entry"),
            ],
            runtimeSymbols: [id("runtime")]
        )
    }

    private func entrypoint(
        _ component: HydrationComponentRecord,
        entry: String
    ) -> ClientComponentEntrypoint {
        ClientComponentEntrypoint(
            componentID: component.id,
            typeName: component.typeName,
            entrySymbols: [id(entry)],
            loadPolicy: component.loadPolicy,
            serverSlots: component.serverSlots.map(\.id)
        )
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
