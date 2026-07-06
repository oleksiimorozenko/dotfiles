# Ticket tracking (template)

Copy into `<vault>/jira/` and adapt. Works with or without a real tracker: the local MDs are the working copies; the tracker, when there is one, stays the system of record. Org-specific process (boards, custom fields, cadence, prefixes) goes in this folder's `CLAUDE.md`, not here.

## Structure

| Path | Purpose |
|---|---|
| `backlog/` | Drafts that aren't scheduled yet |
| `epics/` | One MD per epic or cross-cutting theme; never archived |
| `sprint-YYYY-MM-DD/` | One folder per sprint (start date, ISO), one MD per ticket plus a `README.md` ledger |
| `archive/sprint-YYYY-MM-DD/` | Closed sprints, moved whole |

Contexts without sprints (e.g. personal) use `active/` instead of sprint folders; everything else is identical.

## Rules

- One MD per ticket, ever. Carryover moves the file; the ledgers record provenance. Never `rm`.
- Everything is frontmatter:

```yaml
---
title: Short description
jira: ABC-1234   # tracker ID, or: none
type: task       # task | bug | story | epic | spike
status: todo     # todo | in-progress | done
created: 2026-01-15
epic: "[[<epic-note>]]"      # wikilink; backlinks list an epic's children
parent: "[[<parent-note>]]"  # sub-tasks only
tags: [task]
---
```

- File naming: `YYYY-MM-DD-<short-kebab-topic>.md`, dated by draft creation. Add the tracker ID to the name once it exists.
- Lifecycle: idea (vault `ideas/` or `todos/`) graduates to a draft in `backlog/`, moves into a sprint folder when scheduled, carryover moves the file to the next sprint (dropped work returns to `backlog/`), and the whole folder moves to `archive/` when the sprint closes.
- Each sprint `README.md` is the durable ledger: every ticket that was in that sprint, with carryover direction (`-> carried to` / `<- carried in from`).
- Epics are a frontmatter field, not a folder. Don't hand-maintain child lists; the `epic:` wikilinks make each epic note's backlinks panel do it.
