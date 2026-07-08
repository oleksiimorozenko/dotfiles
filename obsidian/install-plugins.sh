#!/usr/bin/env bash
# Install Obsidian community plugins for a vault from its .obsidian/plugins.txt
# (one GitHub `owner/repo` per line, comments with #). Idempotent; needs curl+jq.
#   usage: obsidian/install-plugins.sh ~/obsidian/<ctx>
set -euo pipefail

VAULT="${1:?usage: install-plugins.sh <vault-path>}"
LIST="$VAULT/.obsidian/plugins.txt"
PLUG="$VAULT/.obsidian/plugins"
[[ -f "$LIST" ]] || { echo "no $LIST, nothing to do"; exit 0; }
mkdir -p "$PLUG"

enabled=()
while IFS= read -r repo; do
  [[ -z "$repo" || "$repo" == \#* ]] && continue
  api="https://api.github.com/repos/$repo/releases/latest"
  tag="$(curl -fsSL "$api" | jq -r .tag_name)"
  id="$(curl -fsSL "https://raw.githubusercontent.com/$repo/HEAD/manifest.json" | jq -r .id)"
  dir="$PLUG/$id"
  mkdir -p "$dir"
  for f in manifest.json main.js styles.css; do
    curl -fsSL -o "$dir/$f" "https://github.com/$repo/releases/download/$tag/$f" 2>/dev/null \
      || { [[ "$f" == "styles.css" ]] || { echo "FAIL $repo: $f"; exit 1; }; }
  done
  enabled+=("$id")
  echo "installed: $id ($repo @ $tag)"
done < "$LIST"

# Enable installed ids (merge with whatever is already enabled)
CP="$VAULT/.obsidian/community-plugins.json"
existing="[]"; [[ -f "$CP" ]] && existing="$(cat "$CP")"
printf '%s\n' "$existing" \
  | jq --argjson add "$(printf '%s\n' "${enabled[@]}" | jq -R . | jq -s .)" \
      '. + $add | unique' > "$CP"
echo "enabled in $CP. Restart Obsidian; turn off Restricted mode once if prompted."
