#!/bin/zsh
# Regenera el icono de la app (Sources/Elkunun/Assets.xcassets/AppIcon.appiconset).
# © 2026 App-Zilla. Licencia MIT.
set -euo pipefail
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
swiftc -module-name IconGenerator Sources/Elkunun/{Theme,TileArt,FoxArt}.swift \
    Tools/IconGenerator/main.swift -o "$build_dir/generate-icon"
"$build_dir/generate-icon" Sources/Elkunun/Assets.xcassets/AppIcon.appiconset
