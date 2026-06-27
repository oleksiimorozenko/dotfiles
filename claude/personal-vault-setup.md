# Handoff: set up a personal Claude vault

Feed this to Claude Code on my personal Mac. Goal: replicate the Claude config architecture I already use, and stand up a personal Obsidian vault. This machine has no memory of the original setup, so this doc is the context.

## The architecture (three tiers)

1. **Public global config** lives in this dotfiles repo under `claude/` (`CLAUDE.md` index, `style.md`, `principles.md`). Symlinked into `~/.claude`. Already present once dotfiles is cloned.
2. **Private global config** is a set of section files (`context`, `operations`, `shell`, `git`, `projects`, `mcp`, `secrets`, `settings.json`) symlinked into `~/.claude` from a private vault's `_claude/` dir.
3. **Project brain** is the vault's notes plus its `memory/` dir.

Key trick: the public `CLAUDE.md` imports everything by absolute path (`@~/.claude/...`). Each machine wires those section filenames to its own local vault, and any missing import simply no-ops. So this machine reuses the same public `CLAUDE.md`/`style`/`principles`, and points the private section files at the personal vault.

Obsidian links are vault-scoped, so the personal vault stays separate from any work vault by design. This personal vault is the connected master for personal stuff (folders like `ideas`, `homelab`, `awsom`).

## Prerequisites

- Claude Code and `gh` installed and authenticated.
- This dotfiles repo cloned. Symlink the public files into `~/.claude`:
  - `~/.claude/CLAUDE.md` -> `dotfiles/claude/CLAUDE.md`
  - `~/.claude/style.md` -> `dotfiles/claude/style.md`
  - `~/.claude/principles.md` -> `dotfiles/claude/principles.md`

## Build the personal vault

1. Skeleton:
   ```
   mkdir -p ~/obsidian/personal/{_claude,_claude/commands,memory,ideas,homelab,awsom,daily,notes,todos}
   ```
2. Private config in `~/obsidian/personal/_claude/`, then symlink each into `~/.claude`:
   - `context.md` — who I am (personal version).
   - Add `operations.md`, `shell.md`, `git.md`, `projects.md` only if useful; absent ones just no-op.
   - `settings.json` — model/theme/permissions, plus `permissions.additionalDirectories` for my home dirs and `"autoMemoryDirectory": "~/obsidian/personal/memory"` (use the absolute path).
   - Symlink: for each file, `ln -sf ~/obsidian/personal/_claude/<f> ~/.claude/<f>`. Edit the real files in the vault, not the symlinks.
3. Commands: `ln -sf ~/obsidian/personal/_claude/commands ~/.claude/commands`. Add a `sync-vault.md` command that runs `git -C ~/obsidian/personal ...` (status, add -A, commit, pull, push). Add matching vault-scoped allow rules (`Bash(git -C ~/obsidian/personal status:*)` etc.) so it runs without prompts.
4. Memory: create `~/obsidian/personal/memory/MEMORY.md` as the index. Core identity/principles live in the config, not memory.
5. Git: `.gitignore` (`.obsidian/workspace*`, `.DS_Store`, `**/secrets/`, `*.key`, `*.pem`, `*.env`), commit, then `gh repo create oleksiimorozenko/obsidian-personal --private --source=. --remote=origin --push`.
6. Git identity: ensure `~/.config/git/config.local` has an `includeIf "gitdir:~/obsidian/"` pointing at the personal identity.
7. Restart Claude, verify with `/memory` that it points at `~/obsidian/personal/memory`.

## Content to seed

- `awsom/` — my own tool. Ingest its repo/notes here. Open item from the work setup: add an `awsom profile status` subcommand (non-destructive auth check).
- `ideas/`, `homelab/`, `daily/`, `notes/`.

## Conventions to carry over

- Style: answer first, then a brief why. No em-dashes, human tone. (In `style.md`, already public.)
- Trust but verify; look things up online for anything version- or time-sensitive. (In `principles.md`.)
- Git: one-line conventional commits, no `Co-Authored-By` trailer; stage, propose message, commit on confirm, push when cleared.
- Sync: git is the source of truth. `/sync-vault` plus a SessionEnd reminder when the vault is dirty; optional Obsidian Git plugin for app-side auto-sync.

## How to drive it

Tell me: "Set up my personal Claude vault following `personal-vault-setup.md`," and I'll create the skeleton, config, symlinks, commands, and the private repo, then confirm before pushing anything public.
