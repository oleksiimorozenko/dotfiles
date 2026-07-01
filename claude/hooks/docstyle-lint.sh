#!/usr/bin/env bash
# docstyle-lint: PostToolUse net for house-style violations on .md writes.
# Hard-fails (exit 2, fed back to Claude) on absolute violations; prints soft
# advisories (exit 0) for judgment calls. Strips code/quotes so examples don't
# false-positive. Pattern library adapted from avoid-ai-writing (MIT, Conor
# Bronsdon); house rules from style.md.
set -uo pipefail

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

# drop fenced code blocks (``` and ~~~), blockquotes, and inline `code` spans so
# CLI flags, globs, and quoted examples don't trip the checks
body=$(awk '
  /^[[:space:]]*```/  {f=!f; next}
  /^[[:space:]]*~~~/  {g=!g; next}
  f||g                {next}
  /^[[:space:]]*>/    {next}
  {print}
' "$file" | sed -E 's/`[^`]*`//g')

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
seen '\*\*[A-Za-z][A-Za-z0-9-]*\*\*' && soft+="  - single-word **bold**: bold only when it earns emphasis\n"

if [ -n "$hard" ]; then
  printf 'docstyle: house-style issues in %s\n%b' "$file" "$hard" >&2
  [ -n "$soft" ] && printf 'advisory:\n%b' "$soft" >&2
  printf 'Fix these (see the docstyle skill), or wrap intentional examples in backticks.\n' >&2
  exit 2
fi
if [ -n "$soft" ]; then
  printf 'docstyle advisory for %s\n%b' "$file" "$soft" >&2
fi
exit 0
