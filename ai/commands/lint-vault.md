---
description: Health-check the current context vault (broken links, orphans, staleness, stale todos, hot.md size)
argument-hint: "[--stale-days N] [--todo-stale-days N]"
---

Run the vault linter against this machine's context vault and triage the output.

1. Identify the vault root (the repo `~/.claude/settings.json` is symlinked from, normally `~/obsidian/<ctx>`).
2. Read the vault's `INDEX.md` to get its knowledge-note folders (Rules section) and its todo and idea folders (defaults `todos` and `ideas`), then run:
   `~/git/oleksiimorozenko/dotfiles/ai/bin/vault-lint.py ~/obsidian/<ctx> --knowledge-dirs <from INDEX rules> --todo-dirs <todo folders> --idea-dirs <idea folders> $ARGUMENTS`
   (assumes the dotfiles clone lives at `~/git/<user>/dotfiles`; adjust the path if it does not)
3. Triage the report with the user, don't mass-fix silently:
   - broken links → fix typos/renames; convert intentional future notes into real stubs or leave with a note
   - orphan knowledge notes → link from the right index/note, or archive
   - stale `synced:` → offer `/jira-sync` (or a Confluence re-sync)
   - missing frontmatter → add the vault's baseline properties
   - oversized `hot.md` → trim to current state
   - stale todos (open, no commit in N days, default 28) → go through them one by one: still planned (touch it with a next step), demote to an idea, move to Jira, or close and archive
   - status vs folder → move the note to the folder its status says, or fix the status
4. Suggest a cadence: run weekly, e.g. after the Friday `/sync-vault`.
