#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if hasFeature(Embedded) && os(WASI)
// wasi-libc's CLOCK_REALTIME is a pointer macro Swift cannot import; call the
// WASI syscall directly. Clock ID 0 = realtime, result in nanoseconds.
@_extern(wasm, module: "wasi_snapshot_preview1", name: "clock_time_get")
@_extern(c)
private func wasiClockTimeGet(_ id: UInt32, _ precision: UInt64, _ time: UnsafeMutablePointer<UInt64>) -> UInt16
#endif

/// Wall-clock seconds since 1970-01-01T00:00:00Z, portable across profiles.
/// On Cloudflare Workers the clock is frozen per request, so one render sees
/// one consistent timestamp.
public enum UnixClock {
    public static func now() -> Double {
        #if hasFeature(Embedded) && os(WASI)
        var nanoseconds: UInt64 = 0
        let status = wasiClockTimeGet(0, 1_000_000, &nanoseconds)
        guard status == 0 else {
            fatalError("wasi clock_time_get failed")
        }
        return Double(nanoseconds) / 1_000_000_000
        #else
        return Date().timeIntervalSince1970
        #endif
    }
}
