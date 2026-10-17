#!/usr/bin/env bash
# docstyle-lint-prose: PreToolUse gate that runs house-style checks on the prose
# an MCP tool is about to post. List-driven: a table maps a tool-name regex to
# how that tool's prose is extracted, so adding a source is one table row (plus
# adding the tool to the matcher in settings.json).
#
# Tables are whitespace-separated, '#' comments and blank lines ignored:
#     <tool-name-regex>   <handler>
# The regex is anchored (^...$) against the tool name. Handlers:
#     flat:f1,f2,...   extract those top-level .tool_input string fields
#     atlassian        official Atlassian/Rovo jira+confluence: commentBody /
#                      summary / title / body / description(string|ADF) /
#                      fields(object -> summary, description)
#     atlassian-custom sooperset/mcp-atlassian jira+confluence: comment / summary /
#                      title / body / content / description(string|ADF) /
#                      fields(JSON string -> summary, description)
# This script's sibling table is always read; extra table paths passed as args
# are read after it (used to layer a private, context-specific table on top).
# First matching row wins.
#
# Reuses docstyle-check.sh (same dir) as the checker. Exit 2 blocks the call so
# the text gets fixed before it posts. Nothing to check -> allow (exit 0).
set -uo pipefail
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CHECK="$DIR/docstyle-check.sh"
[ -x "$CHECK" ] || { echo "docstyle-lint-prose: checker not found at $CHECK; skipping" >&2; exit 0; }

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ -n "$tool" ] || exit 0

handler=""
for tbl in "$DIR/docstyle-prose-sources.tsv" "$@"; do
  [ -f "$tbl" ] || continue
  while read -r rx hnd; do
    case "$rx" in ''|\#*) continue;; esac
    [ -n "$hnd" ] || continue
    if printf '%s' "$tool" | grep -qE "^(${rx})$"; then handler="$hnd"; break; fi
  done < "$tbl"
  [ -n "$handler" ] && break
done
[ -n "$handler" ] || exit 0   # tool not listed -> not linted

case "$handler" in
  atlassian)
    prog='
      def txt: if type=="string" then . elif type=="object" then [.. | .text? // empty] | join(" ") else empty end;
      def asobj: if type=="string" then (fromjson? // {}) else (. // {}) end;
      [ .tool_input.commentBody?, .tool_input.summary?, .tool_input.title?, .tool_input.body?,
        (.tool_input.description? | txt),
        (.tool_input.fields | asobj | .summary?),
        (.tool_input.fields | asobj | .description? | txt)
      ]' ;;
  atlassian-custom)
    prog='
      def txt: if type=="string" then . elif type=="object" then [.. | .text? // empty] | join(" ") else empty end;
      def asobj: if type=="string" then (fromjson? // {}) else (. // {}) end;
      [ .tool_input.summary?, .tool_input.title?, .tool_input.body?, .tool_input.content?,
        (.tool_input.comment? | if type=="string" then . else empty end),
        (.tool_input.description? | txt),
        (.tool_input.fields | asobj | .summary?),
        (.tool_input.fields | asobj | .description? | txt)
      ]' ;;
  flat:*)
    arr=$(printf '%s' "${handler#flat:}" | tr ',' '\n' \
          | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d; s/.*/.tool_input.&?/' | paste -sd, -)
    prog="[ $arr ]" ;;
  *)
    echo "docstyle-lint-prose: unknown handler '$handler' for $tool; skipping" >&2; exit 0 ;;
esac

text=$(printf '%s' "$input" | jq -r "$prog"' | map(select(. != null and . != "")) | join("\n")' 2>/dev/null)
[ -z "${text//[[:space:]]/}" ] && exit 0
printf '%s' "$text" | "$CHECK" "$tool content" hard-only
