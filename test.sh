#!/usr/bin/env bash
set -euo pipefail


REPO="oven-sh/bun"
# Accept version as an argument; fallback to latest release from GitHub if not provided
VERSION="${1:-$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq -r '.tag_name' | sed 's/^bun-v//')}"

echo "🔍 Fetching hashes for Bun v$VERSION..."

PLATFORMS=(
  "x86_64-linux bun-linux-x64.zip"
  "aarch64-linux bun-linux-aarch64.zip"
  "x86_64-darwin bun-darwin-x64-baseline.zip"
  "aarch64-darwin bun-darwin-aarch64.zip"
)

echo ""
echo "passthru.sources = {"

for entry in "${PLATFORMS[@]}"; do
  platform=$(awk '{print $1}' <<< "$entry")
  filename=$(awk '{print $2}' <<< "$entry")
  url="https://github.com/$REPO/releases/download/bun-v$VERSION/$filename"

#   echo "  🛜 Downloading $filename for $platform..." >&2

  base32_hash=$(nix-prefetch-url --unpack "$url" 2>/dev/null)
  sri_hash=$(nix hash to-sri --type sha256 "$base32_hash")

  echo "  \"$platform\" = fetchurl {"
  echo "    url = \"$url\";"
  echo "    hash = \"$sri_hash\";"
  echo "  };"
done

echo "};"