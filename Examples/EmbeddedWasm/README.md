# Client Runtime WASM Profiles

This example builds the same SwiftHTML client runtime source with standard Swift
WASM and Embedded Swift WASM, then compares the produced binary sizes.

Requirements:

- Swift `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a` toolchain
- `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm` Swift SDK
- `swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm-embedded` Swift SDK
- A sibling `JavaScriptKit` checkout at `../../../JavaScriptKit`

Build the Embedded Swift compiler-profile version:

```sh
export SWIFT_BIN="$HOME/Library/Developer/Toolchains/swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a.xctoolchain/usr/bin/swift"
./build.sh
```

Measure standard WASM versus Embedded WASM:

```sh
./measure-size.sh
```

The script writes:

- `.build/size-comparison/standard/Package`
- `.build/size-comparison/embedded/Package`
- `.build/size-comparison/size-report.json`

Run the browser smoke test:

```sh
npm install
npm run test:browser
```

The smoke test serves the example locally, opens Chrome through Playwright,
mounts the SwiftHTML tree, clicks the counter button, and verifies text input.
