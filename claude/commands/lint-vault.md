---
description: Health-check the current context vault (broken links, orphans, staleness, hot.md size)
argument-hint: "[--stale-days N]"
---

Run the vault linter against this machine's context vault and triage the output.

1. Identify the vault root (the repo `~/.claude/settings.json` is symlinked from, normally `~/obsidian/<ctx>`).
2. Read the vault's `INDEX.md` Rules section to get its knowledge-note folders, then run:
   `~/git/root/dotfiles/claude/bin/vault-lint.py ~/obsidian/<ctx> --knowledge-dirs <from INDEX rules> $ARGUMENTS`
3. Triage the report with the user, don't mass-fix silently:
   - broken links → fix typos/renames; convert intentional future notes into real stubs or leave with a note
   - orphan knowledge notes → link from the right index/note, or archive
   - stale `synced:` → offer `/jira-sync` (or a Confluence re-sync)
   - missing frontmatter → add the vault's baseline properties
   - oversized `hot.md` → trim to current state
4. Suggest a cadence: run weekly, e.g. after the Friday `/sync-vault`.
