#!/usr/bin/env bash
# docstyle-lint: house-style gate for .md writes, plus a manual whole-file check.
#   hook (no args): wired as PreToolUse on Write|Edit, so violations never reach
#     disk. Checks only the text being written (Write content, Edit new_string):
#     legacy content elsewhere in the file never blocks an unrelated edit. Works
#     unchanged as PostToolUse (same tool_input), it just reports after the write.
#   manual: docstyle-lint.sh FILE...  checks whole files, any extension. Save
#     remote text (Jira, Confluence) as .txt, not .md, or the hook blocks saving
#     the very text you want to audit.
# Pattern checks live in docstyle-check.sh, shared with docstyle-lint-prose.sh.
# Exit 2 on hard findings (blocks the write in PreToolUse); advisories print on 0.
set -uo pipefail
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

if (($#)); then
  rc=0
  for f in "$@"; do
    if [ ! -f "$f" ]; then
      echo "docstyle-lint: no such file: $f" >&2; ((rc)) || rc=1; continue
    fi
    "$DIR/docstyle-check.sh" "$f" < "$f" || rc=2
  done
  exit "$rc"
fi

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)

# markdown only; everything else passes silently
case "$file" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

# exempt the style-guide sources themselves: they quote the banned words as examples
case "$file" in
  */style.md|*/principles.md|*/docstyle/SKILL.md|*CATEGORIES.md) exit 0 ;;
esac

text=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
[ -n "$text" ] || exit 0

printf '%s' "$text" | "$DIR/docstyle-check.sh" "$file (new text)"
