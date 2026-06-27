# Client Runtime WASM Profiles

This example builds the same SwiftHTML client runtime source with standard Swift
WASM and Embedded Swift WASM, then compares the produced binary sizes.

Requirements:

- Swift 6.3.1 toolchain
- `swift-6.3.1-RELEASE_wasm` Swift SDK
- `swift-6.3.1-RELEASE_wasm-embedded` Swift SDK
- A sibling `JavaScriptKit` checkout at `../../../JavaScriptKit`

Build the Embedded Swift compiler-profile version:

```sh
export SWIFT_BIN="/Users/1amageek/Library/Developer/Toolchains/swift-6.3.1-RELEASE.xctoolchain/usr/bin/swift"
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
