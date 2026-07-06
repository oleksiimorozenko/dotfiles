#!/usr/bin/env bash
# Report-only convergence audit: how far this machine + a context vault are
# from the unified layout (context-setup.md, part B). Changes nothing.
# Exits 1 when anything needs attention.
#   usage: claude/bin/audit.sh ~/obsidian/<ctx>
set -uo pipefail

VAULT="${1:?usage: audit.sh <vault-path>}"
VAULT="$(cd "$VAULT" && pwd)"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
C="$HOME/.claude"
N=0
finding() { printf ' - %s\n' "$1"; N=$((N + 1)); }
shopt -s nullglob

# public-layer links
for f in CLAUDE.md style.md principles.md agents.md; do
  [[ -f "$DOTFILES/claude/$f" && "$(readlink "$C/$f" 2>/dev/null)" != "$DOTFILES/claude/$f" ]] \
    && finding "link missing or wrong: ~/.claude/$f (run bin/bootstrap.sh)"
done
# hooks/skills are real dirs populated per-file (so public/private/local mix);
# check each public entry is linked inside, not that the dir itself is a link.
for d in hooks skills; do
  [[ -d "$DOTFILES/claude/$d" ]] || continue
  for e in "$DOTFILES/claude/$d"/*; do
    [[ -e "$e" ]] || continue
    [[ "$(readlink "$C/$d/$(basename "$e")" 2>/dev/null)" != "$e" ]] \
      && finding "link missing or wrong: ~/.claude/$d/$(basename "$e") (run bin/bootstrap.sh)"
  done
done

# private-layer links, plus strays into other vaults
for f in "$VAULT"/_claude/*.md "$VAULT"/_claude/settings.json; do
  b="$(basename "$f")"
  [[ "$(readlink "$C/$b" 2>/dev/null)" != "$f" ]] && finding "link missing or wrong: ~/.claude/$b"
done
[[ -d "$VAULT/_claude/commands" && "$(readlink "$C/commands" 2>/dev/null)" != "$VAULT/_claude/commands" ]] \
  && finding "link missing or wrong: ~/.claude/commands"
for l in "$C"/*.md "$C"/settings.json "$C"/commands; do
  [[ -L "$l" ]] || continue
  t="$(readlink "$l")"
  [[ "$t" == "$HOME"/obsidian/* && "$t" != "$VAULT"/* ]] \
    && finding "stale link into another vault: ${l/#$HOME/\~} -> ${t/#$HOME/\~}"
done

# settings.json content
S="$VAULT/_claude/settings.json"
if [[ -f "$S" ]]; then
  grep -q '/Users/' "$S" && finding "settings.json: literal /Users/ path (use ~; templates/settings-snippets.md)"
  grep -q 'docstyle-lint\.sh' "$S" || finding "settings.json: docstyle PostToolUse hook not wired"
  grep -q '"deny"' "$S" || finding "settings.json: no secrets deny block"
  grep -q 'autoMemoryDirectory' "$S" || finding "settings.json: autoMemoryDirectory not set"
  grep -q 'SessionEnd' "$S" || finding "settings.json: no SessionEnd nudge"
else
  finding "vault has no _claude/settings.json"
fi

# vault content
[[ -e "$VAULT/_claude/bin/bootstrap.sh" ]] \
  && finding "local bootstrap copy in _claude/bin (this repo's bin/bootstrap.sh is canonical)"
while IFS= read -r f; do
  finding "hardcoded /Users/ path in ${f#"$VAULT"/}"
done < <(grep -rl '/Users/' "$VAULT/_claude" 2>/dev/null | grep -v '/settings.json$')
while IFS= read -r f; do
  finding "memory filename encodes type: memory/$(basename "$f") (kebab-case; type lives in frontmatter)"
done < <(find "$VAULT/memory" -maxdepth 1 -name '*_*' 2>/dev/null)
[[ -f "$VAULT/memory/MEMORY.md" ]] && ! grep -qi 'core facts' "$VAULT/memory/MEMORY.md" \
  && finding "memory/MEMORY.md: missing the core-facts preamble (templates/memory-conventions.md)"
CMD="$VAULT/_claude/commands"
[[ -f "$CMD/sync-vault.md" ]] && ! grep -q 'pull --rebase' "$CMD/sync-vault.md" \
  && finding "commands/sync-vault.md: not on pull --rebase (templates/sync-vault.md)"
[[ -f "$CMD/daily.md" ]] || finding "commands/daily.md: missing (templates/daily.md)"

if ((N == 0)); then
  echo "OK: context converged."
else
  echo "$N finding(s)."
  exit 1
fi
