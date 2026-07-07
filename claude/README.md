# Claude Code config (public)

The shareable part of my Claude Code setup, symlinked into `~/.claude`.

## Layout

- `CLAUDE.md`: index; imports the section files by absolute path (`@~/.claude/...`). Public imports resolve from this repo; private ones (context, operations, secrets pointers, ...) from a per-context vault, and no-op on machines where they're absent.
- `style.md`, `principles.md`, `agents.md`: writing style, working principles, agent delegation.
- `hooks/`: docstyle enforcement. `docstyle-check.sh` is the shared checker; `docstyle-lint.sh` (PostToolUse) gates `.md` writes, `docstyle-lint-prose.sh` (PreToolUse) gates prose posts for the MCP tools listed in `docstyle-prose-sources.tsv` (Jira out of the box; layer a context table for more).
- `skills/docstyle/`: the docstyle skill (registers, tiered vocabulary, detect/rewrite/edit passes).
- `bin/bootstrap.sh`: wires `~/.claude` from this repo plus a context vault (idempotent; unlinks private-layer links left by another vault). `hooks/` and `skills/` are linked per-entry into real dirs so public, private (vault), and machine-local entries can coexist. Usage: `claude/bin/bootstrap.sh ~/obsidian/<ctx>`.
- `bin/audit.sh`: report-only convergence check for a context; prints what still diverges from the unified layout. Usage: `claude/bin/audit.sh ~/obsidian/<ctx>`.
- `templates/`: per-context starting points (settings snippets, sync-vault and daily commands, daily note template, memory conventions, ticket-folder structure).
- `context-setup.md`: new-machine setup and the convergence checklist for older contexts.

## Architecture

Three tiers: public config (this repo), private per-context config (a vault's `_claude/`, symlinked into `~/.claude`), and the vault itself (notes plus auto-memory). One context per machine; all machines share this public layer. Details in `context-setup.md`.

## Conventions

- Paths are `~`-relative in configs, commands, and docs; `$HOME` in scripts. Never a literal `/Users/<name>`: file permission rules resolve `~` against the real home, and Bash rules match literal command text, so commands must be written with `~` for the allowlist to hold across machines.
- Nothing context-identifying or secret lands in this repo: no org names, emails, ids, tokens, or real machine paths. All of that lives in the private vaults. Templates use `<ctx>`-style placeholders.
- Always edit the real files (here or in the vault), never the `~/.claude` symlinks.
