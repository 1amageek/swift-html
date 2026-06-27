#!/bin/bash
set -euo pipefail

package_dir="$(cd "$(dirname "$0")" && pwd)"
swift_bin="${SWIFT_BIN:-${SWIFT:-swift}}"
swift_sdk_base="${SWIFT_SDK_ID_wasm32_unknown_wasip1:-${SWIFT_SDK_ID:-swift-6.3.1-RELEASE_wasm}}"
output_dir="$package_dir/.build/size-comparison"

case "$swift_sdk_base" in
  *-embedded)
    standard_sdk="${swift_sdk_base%-embedded}"
    embedded_sdk="$swift_sdk_base"
    ;;
  *)
    standard_sdk="$swift_sdk_base"
    embedded_sdk="${swift_sdk_base}-embedded"
    ;;
esac

build_mode() {
  local mode="$1"
  local sdk="$2"

  rm -rf \
    "$package_dir/.build/wasm32-unknown-wasip1/release" \
    "$package_dir/.build/plugins/PackageToJS/outputs/Package" \
    "$package_dir/.build/plugins/PackageToJS/outputs/Package.tmp"

  if [ "$mode" = "embedded" ]; then
    env \
      SWIFTHTML_CLIENT_RUNTIME_PROFILE=embedded \
      JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=1 \
      "$swift_bin" package \
        --build-system native \
        --package-path "$package_dir" \
        --swift-sdk "$sdk" \
        js \
        -c release
  else
    "$swift_bin" package \
      --build-system native \
      --package-path "$package_dir" \
      --swift-sdk "$sdk" \
      js \
      -c release
  fi

  mkdir -p "$output_dir/$mode"
  rm -rf "$output_dir/$mode/Package"
  cp -R "$package_dir/.build/plugins/PackageToJS/outputs/Package" "$output_dir/$mode/Package"
}

byte_count() {
  wc -c < "$1" | tr -d ' '
}

gzip_count() {
  gzip -c -9 "$1" | wc -c | tr -d ' '
}

brotli_count() {
  if command -v brotli >/dev/null 2>&1; then
    brotli -c -q 11 "$1" | wc -c | tr -d ' '
  else
    echo ""
  fi
}

ratio() {
  awk -v before="$1" -v after="$2" 'BEGIN {
    if (before == 0) {
      print "0.0"
    } else {
      printf "%.1f", (1 - (after / before)) * 100
    }
  }'
}

row() {
  local label="$1"
  local standard="$2"
  local embedded="$3"
  local saved
  saved="$(ratio "$standard" "$embedded")"
  printf "%-12s %12s %12s %8s%%\n" "$label" "$standard" "$embedded" "$saved"
}

echo "Building SwiftHTML standard WASM with $standard_sdk"
build_mode "standard" "$standard_sdk"

echo "Building SwiftHTML Embedded WASM with $embedded_sdk"
build_mode "embedded" "$embedded_sdk"

standard_wasm="$output_dir/standard/Package/ClientRuntimeHTMLApp.wasm"
embedded_wasm="$output_dir/embedded/Package/ClientRuntimeHTMLApp.wasm"

standard_raw="$(byte_count "$standard_wasm")"
embedded_raw="$(byte_count "$embedded_wasm")"
standard_gzip="$(gzip_count "$standard_wasm")"
embedded_gzip="$(gzip_count "$embedded_wasm")"
standard_brotli="$(brotli_count "$standard_wasm")"
embedded_brotli="$(brotli_count "$embedded_wasm")"
if [ -n "$standard_brotli" ] && [ -n "$embedded_brotli" ]; then
  brotli_reduction="\"$(ratio "$standard_brotli" "$embedded_brotli")\""
else
  brotli_reduction="null"
fi

report_path="$output_dir/size-report.json"
cat > "$report_path" <<EOF
{
  "standard": {
    "sdk": "$standard_sdk",
    "wasm": "$standard_wasm",
    "rawBytes": $standard_raw,
    "gzipBytes": $standard_gzip,
    "brotliBytes": ${standard_brotli:-null}
  },
  "embedded": {
    "sdk": "$embedded_sdk",
    "wasm": "$embedded_wasm",
    "rawBytes": $embedded_raw,
    "gzipBytes": $embedded_gzip,
    "brotliBytes": ${embedded_brotli:-null}
  },
  "reductionPercent": {
    "raw": "$(ratio "$standard_raw" "$embedded_raw")",
    "gzip": "$(ratio "$standard_gzip" "$embedded_gzip")",
    "brotli": $brotli_reduction
  }
}
EOF

printf "\n%-12s %12s %12s %9s\n" "Encoding" "Standard" "Embedded" "Reduction"
printf "%-12s %12s %12s %9s\n" "--------" "--------" "--------" "---------"
row "raw" "$standard_raw" "$embedded_raw"
row "gzip" "$standard_gzip" "$embedded_gzip"
if [ -n "$standard_brotli" ] && [ -n "$embedded_brotli" ]; then
  row "brotli" "$standard_brotli" "$embedded_brotli"
else
  printf "%-12s %12s %12s %9s\n" "brotli" "missing" "missing" "n/a"
fi

echo
echo "Standard output: $output_dir/standard/Package"
echo "Embedded output: $output_dir/embedded/Package"
echo "JSON report: $report_path"
