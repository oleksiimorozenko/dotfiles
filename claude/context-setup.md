# Context setup and convergence

How a machine gets wired to this Claude config: the public layer from this repo, the private layer from a per-context vault at `~/obsidian/<ctx>`. Part A stands up a new context; part B converges a context that predates the unified layout. Feed this file to Claude Code and say "set up this context" or "converge this context".

## The architecture (three tiers)

1. Public global config: this repo's `claude/` (`CLAUDE.md` index, `style.md`, `principles.md`, `agents.md`, `hooks/`, `skills/`). Symlinked into `~/.claude`.
2. Private global config: the vault's `_claude/` (section files, `settings.json`, `commands/`), symlinked into `~/.claude`. The public `CLAUDE.md` imports every section by absolute path (`@~/.claude/...`); a missing private file simply no-ops.
3. The vault itself: notes plus `memory/` (auto-memory travels with the vault via git).

One context is wired per machine; every machine shares the public layer.

## A. New machine or new context

1. Clone this repo and the (private) context vault.
2. Run `claude/bin/bootstrap.sh ~/obsidian/<ctx>`. It derives the repo location from itself, links the public files and dirs, then the vault's `_claude/` files and `commands/`. It never clobbers a real file.
3. If the vault is new, create its `_claude/` from `claude/templates/`:
   - `settings.json`: assemble from the blocks in `templates/settings-snippets.md`, then add personal keys (model, theme, notifications).
   - `context.md` (who I am in this context) and `git.md` (branch and commit conventions, plus the vault sync carve-out). Add `operations.md`, `shell.md`, `projects.md`, `mcp.md`, `secrets.md` as they become useful.
   - `commands/`: copy `templates/sync-vault.md` and `templates/daily.md`, fill the placeholders. Copy `templates/daily-note-template.md` to `<vault>/daily/_template.md`.
   - `memory/MEMORY.md` per `templates/memory-conventions.md`.
   - `jira/` from `templates/jira-vault/` if the context tracks tickets (works tracker-less too).
4. Vault git hygiene: `.gitignore` with `.obsidian/workspace*`, `.DS_Store`, `**/secrets/`, `*.key`, `*.pem`, `*.env`; private remote; `includeIf "gitdir:~/obsidian/"` pointing at the personal git identity.
5. Restart Claude. Verify: `/memory` shows the vault memory dir, `/hooks` shows docstyle wired, `/permissions` shows the rules, and a test `.md` write containing an em-dash gets flagged by the hook.

## B. Converge an existing context

0. Run `claude/bin/audit.sh ~/obsidian/<ctx>` for the mechanical findings list (links, settings gaps, hardcoded paths, memory naming). The steps below cover those findings plus the judgment calls the script can't see.
1. Pull this repo, rerun `claude/bin/bootstrap.sh ~/obsidian/<ctx>`. This adds links older setups miss (`agents.md`, `hooks/`, `skills/`).
2. `settings.json`, against `templates/settings-snippets.md`:
   - drop allow rules for built-in read-only commands (`ls`, `cat`, `grep`, `find`, `head`, `tail`, `wc`, `stat`, `du`, `sort`, `uniq`, `which`, read-only `git` forms); keep non-builtin tools and the vault `git -C` prefix rules
   - replace every literal `/Users/<name>` with the `~` form (file rules resolve `~`; Bash rules match literal command text, and commands are written with `~`)
   - adopt the secrets deny block
   - wire the docstyle hooks and SessionEnd nudges
   - point `autoMemoryDirectory` at `~/obsidian/<ctx>/memory`
3. Commands: replace `sync-vault.md` with the template instance (`pull --rebase`, autocommit carve-out; note the carve-out in `_claude/git.md`). Add or refit `daily.md`.
4. Memory: converge on `templates/memory-conventions.md`. Kebab-case renames via `git mv`, fix wikilinks and MEMORY.md lines, add the index preamble.
5. Scripts under `_claude/bin/`: replace hardcoded home paths with `$HOME`; delete any local bootstrap copy (this repo's is canonical).
6. Ticket folder: adopt the `templates/jira-vault/` structure where it fits; org process stays in that folder's `CLAUDE.md`.
7. Verify as in A.5, then `/sync-vault`.
