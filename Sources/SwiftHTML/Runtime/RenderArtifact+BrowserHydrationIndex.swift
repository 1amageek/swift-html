public extension RenderArtifact {
    func browserHydrationIndex() -> BrowserHydrationIndex {
        BrowserHydrationIndexExporter().export(self)
    }
}
