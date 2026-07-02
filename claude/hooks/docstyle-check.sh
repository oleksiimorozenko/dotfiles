#!/usr/bin/env bash
# docstyle-check: shared house-style checker. Reads text on stdin, strips
# code/quotes so examples don't false-positive, then hard-fails (exit 2, fed
# back to Claude) on absolute violations and prints soft advisories (exit 0)
# for judgment calls. Callers handle source-specific gating and labeling.
#   $1 = label shown in the message (file path, tool name, ...)
#   $2 = "hard-only" to suppress the soft advisory (e.g. tickets/comments)
# Pattern library adapted from avoid-ai-writing (MIT, Conor Bronsdon); house
# rules from style.md. Kept in sync with docstyle-lint.sh + docstyle-lint-jira.sh.
set -uo pipefail
label="${1:-input}"
mode="${2:-}"

# drop fenced code blocks (``` and ~~~), blockquotes, and inline `code` spans so
# CLI flags, globs, and quoted examples don't trip the checks
body=$(awk '
  /^[[:space:]]*```/  {f=!f; next}
  /^[[:space:]]*~~~/  {g=!g; next}
  f||g                {next}
  /^[[:space:]]*>/    {next}
  {print}
' | sed -E 's/`[^`]*`//g')

hard=""; soft=""
seen() { grep -nEi "$1" <<<"$body" >/dev/null 2>&1; }

# --- hard: absolute house rules + P0 fingerprints (block, exit 2) ---
seen '—'                 && hard+="  - em-dash (—): rephrase; commas, parens, or \"to\" for ranges\n"
seen '(^| )--( |$)'      && hard+="  - \" -- \" as em-dash: rephrase\n"
for pat in \
  "[Ii]t'?s worth noting" \
  "\bdelv(e|es|ing|ed)\b" \
  "\bboasts?\b" \
  "a testament to" \
  "[Rr]est assured" \
  "[Ii]n today'?s[^.]{0,20}fast-paced" \
  "[Nn]ot only .{1,60}? but also" ; do
  seen "$pat" && hard+="  - banned phrase: /$pat/\n"
done
for pat in \
  "cite(turn|news|search)[0-9]" \
  "oai_citation" \
  "contentReference\[oaicite" \
  "utm_source=(chatgpt|openai|copilot|claude|perplexity|gemini|grok)" \
  "\[(Your|Insert|Add|Enter|Describe|Specify|TODO|TBD|PLACEHOLDER)[^]]*\]" \
  "(19|20)[0-9]{2}-XX-XX" \
  "as of my (last update|knowledge cut)" \
  "as an? (AI|artificial intelligence|large language)" ; do
  seen "$pat" && hard+="  - AI-tool fingerprint: /$pat/\n"
done

# --- soft: judgment calls (advisory, exit 0 unless a hard finding also fired) ---
if [ "$mode" != "hard-only" ]; then
  seen '\*\*[A-Za-z][A-Za-z0-9-]*\*\*' && soft+="  - single-word **bold**: bold only when it earns emphasis\n"
fi

if [ -n "$hard" ]; then
  printf 'docstyle: house-style issues in %s\n%b' "$label" "$hard" >&2
  [ -n "$soft" ] && printf 'advisory:\n%b' "$soft" >&2
  printf 'Fix these (see the docstyle skill), or wrap intentional examples in backticks.\n' >&2
  exit 2
fi
if [ -n "$soft" ]; then
  printf 'docstyle advisory for %s\n%b' "$label" "$soft" >&2
fi
exit 0
