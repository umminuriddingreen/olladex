#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIGURATION=${CONFIGURATION:-release}
OUTPUT="$ROOT/dist/Olladex.app"

cd "$ROOT"
swift build -c "$CONFIGURATION"
BIN=$(swift build -c "$CONFIGURATION" --show-bin-path)/Olladex

rm -rf "$OUTPUT"
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources"
cp "$BIN" "$OUTPUT/Contents/MacOS/Olladex"
cp "$ROOT/Support/Info.plist" "$OUTPUT/Contents/Info.plist"
codesign --force --deep --sign - "$OUTPUT"
echo "$OUTPUT"
