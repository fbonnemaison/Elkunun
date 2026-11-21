#!/bin/zsh
# Regenera el icono de la app (Sources/Elkunun/Assets.xcassets/AppIcon.appiconset)
# a partir de Design/AppIcon-source.png.
# © 2026 App-Zilla. Licencia MIT.
set -euo pipefail
cd "$(dirname "$0")/.."
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
swiftc Tools/IconGenerator/main.swift -o "$build_dir/generate-icon"
"$build_dir/generate-icon" Design/AppIcon-source.png Sources/Elkunun/Assets.xcassets/AppIcon.appiconset
