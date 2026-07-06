#!/usr/bin/env bash
# Wire ~/.claude from two sources: this dotfiles repo (public) and a context
# vault (private). Idempotent; never clobbers a real file.
#   usage: claude/bin/bootstrap.sh ~/obsidian/<ctx>
set -euo pipefail

VAULT="${1:?usage: bootstrap.sh <vault-path>}"
VAULT="$(cd "$VAULT" && pwd)"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

link() {  # link <target> <linkname>; never clobber a real file
  local target="$1" name="$2"
  if [[ -e "$name" && ! -L "$name" ]]; then
    echo "skip (real file): $name"; return
  fi
  ln -sfn "$target" "$name"
  echo "linked: ${name/#$HOME/\~} -> ${target/#$HOME/\~}"
}

# Public: files and whole dirs from this repo
for f in CLAUDE.md style.md principles.md agents.md; do
  [[ -f "$DOTFILES/claude/$f" ]] && link "$DOTFILES/claude/$f" "$CLAUDE_DIR/$f"
done
for d in hooks skills; do
  [[ -d "$DOTFILES/claude/$d" ]] && link "$DOTFILES/claude/$d" "$CLAUDE_DIR/$d"
done

# Rewire guard: drop private-layer links that point into a different vault,
# so switching a machine's context can't leave stale section files behind
shopt -s nullglob
for l in "$CLAUDE_DIR"/*.md "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/commands"; do
  [[ -L "$l" ]] || continue
  t="$(readlink "$l")"
  if [[ "$t" == "$HOME"/obsidian/* && "$t" != "$VAULT"/* ]]; then
    rm "$l"; echo "unlinked (other vault): ${l/#$HOME/\~} -> ${t/#$HOME/\~}"
  fi
done

# Private: the vault's _claude/ (section files, settings.json, commands)
for f in "$VAULT"/_claude/*.md "$VAULT"/_claude/settings.json; do
  link "$f" "$CLAUDE_DIR/$(basename "$f")"
done
[[ -d "$VAULT/_claude/commands" ]] && link "$VAULT/_claude/commands" "$CLAUDE_DIR/commands"

# Git identity check (non-destructive; warns only)
GITLOCAL="$HOME/.config/git/config.local"
if [[ -f "$GITLOCAL" ]] && ! grep -q 'gitdir:~/obsidian/' "$GITLOCAL"; then
  echo "NOTE: add to $GITLOCAL ->  [includeIf \"gitdir:~/obsidian/\"]  path = ~/.config/git/config.personal"
fi

echo "Done. Restart Claude; verify with /memory, /hooks, /permissions."
