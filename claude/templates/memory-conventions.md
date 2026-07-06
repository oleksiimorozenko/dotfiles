# Auto-memory conventions

Applies to every context vault. `autoMemoryDirectory` points at the vault's `memory/`, so memories travel with the vault via git.

## Files

- One fact per file. Kebab-case filename matching the `name:` field (`db-failover-quirk.md`, not `ref_db_failover_quirk.md`; the type lives in frontmatter, not the filename).
- Frontmatter:

```markdown
---
name: <kebab-slug>
description: <one line; used to decide recall relevance>
metadata:
  type: user | feedback | project | reference
---
```

- Body: the fact itself. `feedback` and `project` entries add `**Why:**` and `**How to apply:**` lines. Link related memories with `[[name]]`.

## MEMORY.md (the index)

One line per memory: `- [Title](file.md) - hook`. Start the file with a preamble so core facts don't drift into memory:

> Auto-memory index, one line per note. Core facts are NOT kept here: who I am lives in `_claude/context.md`, working principles in the public `principles.md`, ops shorthand in the other `_claude/*.md`. Memory is for genuinely new, evolving facts learned over time.

## Hygiene

- Update or delete a stale memory instead of adding a near-duplicate.
- Never store secret values; credentials are references (store item name, path) only.
- Don't record what the repo, CLAUDE.md, or git history already records.
