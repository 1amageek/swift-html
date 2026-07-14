#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

#if hasFeature(Embedded) && os(WASI)
// wasi-libc's getenv depends on constructor-driven environ setup, which the
// Embedded link does not run; read the environment via the WASI syscalls
// directly instead.
@_extern(wasm, module: "wasi_snapshot_preview1", name: "environ_sizes_get")
@_extern(c)
private func wasiEnvironSizesGet(
    _ count: UnsafeMutablePointer<UInt32>,
    _ bufferSize: UnsafeMutablePointer<UInt32>
) -> UInt16

@_extern(wasm, module: "wasi_snapshot_preview1", name: "environ_get")
@_extern(c)
private func wasiEnvironGet(
    _ environ: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
    _ buffer: UnsafeMutablePointer<UInt8>
) -> UInt16
#endif

/// Process environment lookup, portable across profiles. On WASI the host
/// shim supplies the variables (Cloudflare Workers map their `env` bindings
/// into it); elsewhere Foundation's ProcessInfo.
public enum ProcessEnvironment {
    public static func value(_ name: String) -> String? {
        #if hasFeature(Embedded) && os(WASI)
        var count: UInt32 = 0
        var bufferSize: UInt32 = 0
        guard wasiEnvironSizesGet(&count, &bufferSize) == 0, count > 0 else {
            return nil
        }
        let pointers = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: Int(count))
        defer { pointers.deallocate() }
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))
        defer { buffer.deallocate() }
        guard wasiEnvironGet(pointers, buffer) == 0 else {
            return nil
        }
        let prefix = Array((name + "=").utf8)
        for index in 0..<Int(count) {
            guard let entry = pointers[index] else {
                continue
            }
            var bytes: [UInt8] = []
            var cursor = entry
            while cursor.pointee != 0 {
                bytes.append(cursor.pointee)
                cursor += 1
            }
            if bytes.count > prefix.count, Array(bytes[..<prefix.count]) == prefix {
                return String(decoding: bytes[prefix.count...], as: UTF8.self)
            }
        }
        return nil
        #else
        return ProcessInfo.processInfo.environment[name]
        #endif
    }
}
