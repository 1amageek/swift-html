#!/bin/bash
set -euo pipefail

fixture_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$fixture_dir/../.." && pwd)"
swift_bin="${SWIFT_WEB_WASM_SWIFT:-${SWIFT_HTML_WASM_SWIFT:-$(command -v swift)}}"
swift_toolchain_bin="${SWIFT_WEB_WASM_TOOLCHAIN_BIN:-${SWIFT_HTML_WASM_TOOLCHAIN_BIN:-$(cd "$(dirname "$swift_bin")" && pwd)}}"
swift_sdk_standard="swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-08-14-a_wasm"
swift_sdk_embedded="swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-08-14-a_wasm-embedded"

if [[ ! -x "$swift_bin" ]]; then
    echo "Swift executable is not available: $swift_bin" >&2
    exit 1
fi
if [[ ! -x "$swift_toolchain_bin/wasm-ld" ]]; then
    echo "Pinned Swift toolchain bin must contain wasm-ld: $swift_toolchain_bin" >&2
    echo "Set SWIFT_WEB_WASM_SWIFT and SWIFT_WEB_WASM_TOOLCHAIN_BIN to the same snapshot." >&2
    exit 1
fi
swift_version="$("$swift_bin" --version)"
if [[ "$swift_version" != *"Swift 424cae54c1a10da"* ]]; then
    echo "Unexpected Swift snapshot; expected compiler commit 424cae54c1a10da:" >&2
    echo "$swift_version" >&2
    exit 1
fi
swift_static_resources_path="$("$swift_bin" sdk configure --show-configuration \
    "$swift_sdk_embedded" wasm32-unknown-wasip1 \
    | awk -F': ' '$1 == "swiftStaticResourcesPath" { print $2; exit }')"
unicode_tables="$(dirname "$swift_static_resources_path")/swift/embedded/wasm32-unknown-wasip1/libswiftUnicodeDataTables.a"
if [[ -z "$swift_static_resources_path" || ! -f "$unicode_tables" ]]; then
    echo "Pinned Embedded Unicode archive is not available: $unicode_tables" >&2
    exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/swift-html-state-store-validation.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$work_dir/Sources/SwiftHTML" "$work_dir/Sources/EmbeddedStateStoreValidation"
rsync -a --exclude='Preview' "$repo_root/Sources/SwiftHTML/" "$work_dir/Sources/SwiftHTML/"
cp "$fixture_dir/Package.swift" "$work_dir/Package.swift"
cp "$fixture_dir/Sources/EmbeddedStateStoreValidation/Validation.swift" \
    "$work_dir/Sources/EmbeddedStateStoreValidation/Validation.swift"

cmp "$repo_root/Sources/SwiftHTML/Core/State.swift" \
    "$work_dir/Sources/SwiftHTML/Core/State.swift"
cmp "$repo_root/Sources/SwiftHTML/Core/RuntimeValueBox.swift" \
    "$work_dir/Sources/SwiftHTML/Core/RuntimeValueBox.swift"
cmp "$repo_root/Sources/SwiftHTML/Core/SwiftHTMLMutex.swift" \
    "$work_dir/Sources/SwiftHTML/Core/SwiftHTMLMutex.swift"

echo "Swift executable: $swift_bin"
echo "Swift toolchain bin: $swift_toolchain_bin"
echo "$swift_version"
echo "Standard SDK: $swift_sdk_standard"
echo "Embedded SDK: $swift_sdk_embedded"
echo "Unicode archive: $unicode_tables"
echo "State.swift SHA256: $(shasum -a 256 "$work_dir/Sources/SwiftHTML/Core/State.swift" | awk '{print $1}')"

run_profile() {
    local profile="$1"
    local sdk="$2"
    local configuration="$3"
    local embedded="$4"

    echo "== $profile $configuration build =="
    if [[ "$embedded" == "1" ]]; then
        SWIFT_HTML_EMBEDDED=1 SWIFT_HTML_UNICODE_TABLES="$unicode_tables" "$swift_bin" build \
            --package-path "$work_dir" \
            --swift-sdk "$sdk" \
            --configuration "$configuration" \
            --jobs 2
        echo "== $profile $configuration run =="
        SWIFT_HTML_EMBEDDED=1 SWIFT_HTML_UNICODE_TABLES="$unicode_tables" "$swift_bin" run \
            --package-path "$work_dir" \
            --swift-sdk "$sdk" \
            --configuration "$configuration" \
            --skip-build
    else
        SWIFT_HTML_UNICODE_TABLES="$unicode_tables" env -u SWIFT_HTML_EMBEDDED "$swift_bin" build \
            --package-path "$work_dir" \
            --swift-sdk "$sdk" \
            --configuration "$configuration" \
            --jobs 2
        echo "== $profile $configuration run =="
        SWIFT_HTML_UNICODE_TABLES="$unicode_tables" env -u SWIFT_HTML_EMBEDDED "$swift_bin" run \
            --package-path "$work_dir" \
            --swift-sdk "$sdk" \
            --configuration "$configuration" \
            --skip-build
    fi
}

run_profile "Embedded WASM" "$swift_sdk_embedded" debug 1
run_profile "Embedded WASM" "$swift_sdk_embedded" release 1
run_profile "standard WASM" "$swift_sdk_standard" debug 0
