#!/usr/bin/env bash
# docstyle-lint: PostToolUse net for house-style violations on .md writes.
# Handles markdown-only gating and style-source exemptions, then delegates the
# actual pattern checks to docstyle-check.sh (shared with the Jira PreToolUse
# hook). Exit 2 is fed back to Claude; soft advisories print on exit 0.
set -uo pipefail
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)

# markdown only; everything else passes silently
case "$file" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# exempt the style-guide sources themselves — they quote the banned words as examples
case "$file" in
  */style.md|*/principles.md|*/docstyle/SKILL.md|*CATEGORIES.md) exit 0 ;;
esac

"$DIR/docstyle-check.sh" "$file" < "$file"
