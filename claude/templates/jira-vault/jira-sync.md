---
description: Reconcile local Jira mirrors with the board (read-only against Jira)
argument-hint: "[7d|1m|since-last|free-form criteria]"
---

<!-- Template: copy to <vault>/_claude/commands/jira-sync.md, replace <ctx> and
     <PROJECT>, adapt folder names to the vault's stage layout (backlog/ ->
     active/ or sprint-*/ -> archive/), delete this comment. -->

Reconcile `~/obsidian/<ctx>/jira/` mirrors against Jira. **Jira is the source of truth for ticket state; local MDs are the working mirror.** This command never writes to Jira — drafting, pushing, and transitioning tickets stays the normal `jira/CLAUDE.md` flow.

## Window

- No arguments: last 7 days (`updated >= -7d`).
- `$ARGUMENTS` like `1m`, `14d`: use as the JQL window.
- `since-last`: per-ticket `synced` frontmatter as the watermark — window from the oldest `synced` among mirrors.
- Anything else is free-form criteria — interpret it (an epic, a sprint, "with comments", ...).

## Backend

Resolve Atlassian access from `~/.claude/mcp.md`; project key, field ids, and JQL quirks from `jira/CLAUDE.md` / `jira/README.md`. If no Atlassian tooling is available in this session, stop and say so — never fake a sync from local files.

## Steps

1. Query: `project = "<PROJECT>" AND assignee = currentUser() AND updated >= -<window>` (or the free-form criteria). The user's tickets only.
2. Reconcile results against local mirrors in the active stage folders (`archive/` only when the criteria cover history): status drift → update frontmatter (move MDs between stages per the vault's lifecycle); missing mirror → list, create only for tickets the user drives; closed in Jira → update + archive per lifecycle.
3. Comments: only when the criteria ask. Store under `## Comments (synced YYYY-MM-DD)`.
4. Stamp `synced: <ISO8601 UTC>` on **every mirror checked**, changed or not (staleness view relies on it).
5. Report a drift table: new / changed / closed / local-only. No silent changes.
