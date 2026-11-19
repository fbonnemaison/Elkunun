#!/bin/zsh
# Regenera los 60 niveles de la campaña (Sources/ElkununCore/CampaignLevels.swift).
# © 2026 App-Zilla. Licencia MIT.
set -euo pipefail
cd "$(dirname "$0")/.."

build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT

sources=(${(f)"$(ls Sources/ElkununCore/*.swift | grep -v CampaignLevels.swift)"})
cat > "$build_dir/CampaignLevels.swift" <<'SWIFT'
enum CampaignLevels { static let entries: [Campaign.Entry] = [] }
SWIFT

swiftc -O -module-name CampaignGenerator "${sources[@]}" "$build_dir/CampaignLevels.swift" \
    Tools/CampaignGenerator/main.swift -o "$build_dir/generate-campaign"
"$build_dir/generate-campaign" Sources/ElkununCore/CampaignLevels.swift
