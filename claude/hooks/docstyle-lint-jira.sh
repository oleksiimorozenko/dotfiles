#!/usr/bin/env bash
# docstyle-lint-jira: PreToolUse gate for Jira posts. Pulls the prose fields out
# of the MCP tool input (commentBody for comments; summary + description for
# create/edit, handling markdown strings or ADF objects) and runs them through
# docstyle-check.sh. Exit 2 blocks the call so Claude fixes the text before it
# reaches Jira. Nothing to check (e.g. an edit that only sets sprint/status) -> allow.
set -uo pipefail
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

input=$(cat)

text=$(printf '%s' "$input" | jq -r '
  [
    .tool_input.summary?,
    .tool_input.fields?.summary?,
    .tool_input.commentBody?,
    (.tool_input.comment? | if type=="string" then . else empty end),
    (.tool_input.description?         | if type=="string" then . elif type=="object" then [.. | .text? // empty] | join(" ") else empty end),
    (.tool_input.fields?.description? | if type=="string" then . elif type=="object" then [.. | .text? // empty] | join(" ") else empty end)
  ] | map(select(. != null and . != "")) | join("\n")
' 2>/dev/null)

[ -z "${text//[[:space:]]/}" ] && exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // "jira"' 2>/dev/null)
printf '%s' "$text" | "$DIR/docstyle-check.sh" "$tool content" hard-only
