#if hasFeature(Embedded)
/// Embedded Swift has no `Codable`; state persistence degrades to in-memory
/// only, so constraints written as `CodableWhenAvailable` reduce to `Sendable`.
public typealias CodableWhenAvailable = Sendable
#else
/// Resolves to `Codable` on profiles that support it, so public generic
/// constraints stay identical to their pre-portability spelling.
public typealias CodableWhenAvailable = Codable
#endif
