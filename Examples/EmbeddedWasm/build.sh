#!/bin/bash
set -euxo pipefail

package_dir="$(cd "$(dirname "$0")" && pwd)"
swift_bin="${SWIFT_BIN:-${SWIFT:-swift}}"
swift_sdk_base="${SWIFT_SDK_ID_wasm32_unknown_wasip1:-${SWIFT_SDK_ID:-swift-6.3.1-RELEASE_wasm}}"

case "$swift_sdk_base" in
  *-embedded)
    swift_sdk="$swift_sdk_base"
    ;;
  *)
    swift_sdk="${swift_sdk_base}-embedded"
    ;;
esac

env \
  SWIFTHTML_EXPERIMENTAL_EMBEDDED_WASM=1 \
  JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=1 \
  "$swift_bin" package \
    --build-system native \
    --package-path "$package_dir" \
    --swift-sdk "$swift_sdk" \
    js \
    -c release
