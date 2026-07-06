---
description: Build or refresh today's daily work-log note
argument-hint: "[YYYY-MM-DD]  # optional, defaults to today (for backfill)"
---

<!-- Template: copy to <vault>/_claude/commands/daily.md, fill the parameters,
     delete the sections that don't apply, delete this comment. -->

Context parameters (fill per vault):

- VAULT = `~/obsidian/<ctx>`
- REPOS = `~/git/<org>/*` (canonical clone path only; don't also scan symlinked aliases like `~/code`)
- AUTHOR = `<git author email or name>`
- TICKETS = `mcp` (fill the query block in step 3) or `local`
- DRAFTS = `<VAULT>/jira` (local ticket drafts; conventions in that folder's CLAUDE.md)
- DELTAS = `memory/ todos/ ideas/ jira/`
- SLACK = `yes` or `no`

Build or refresh the daily note at `<VAULT>/daily/<DATE>.md`: a work log / retro rollup of what I did that day, harvested from git, tickets, and the vault.

`DATE` = `$1` if given (backfill), else today (`date +%F`). Backfill caveat: git is accurate for any past date; ticket and Slack "today" filters are only reliable for the current day, so note possible gaps in those sections when backfilling.

## 1. Ensure the note exists

`NOTE=<VAULT>/daily/<DATE>.md`. If it doesn't exist, create it from `<VAULT>/daily/_template.md` with every `{{DATE}}` replaced by `<DATE>`. If it exists, leave the manual sections (`Summary`, `Notes & decisions`, `Carry to tomorrow`) untouched.

## 2. Harvest git commits

Only REPOS, author AUTHOR, in one shell call:

```bash
D="<DATE>"
for repo in <REPOS>/; do
  out=$(git -C "$repo" log --all --author=<AUTHOR> \
        --since="$D 00:00:00" --until="$D 23:59:59" \
        --pretty=format:'- `%h` %s' 2>/dev/null | sort -u)
  [ -n "$out" ] && printf '\n**%s**\n%s\n' "$(basename "$repo")" "$out"
done
```

`--all` catches commits on any branch, not just the checked-out one. If nothing, write `_No commits._`.

## 3. Harvest tickets

With TICKETS = `mcp`, run two queries against this context's tracker MCP (fill in: server, cloudId or org, any JQL quirks):

- Touched today: `assignee = currentUser() AND updated >= "<DATE> 00:00" AND updated < "<DATE> 23:59" ORDER BY updated DESC`
- Current sprint state, for context: `sprint in openSprints() AND assignee = currentUser() ORDER BY rank ASC`

List touched tickets as `- [<ID>] summary (status)`, my tickets only. When a local draft exists under DRAFTS, wikilink the ID to it (`[[<draft-file>|<ID>]]`).

With TICKETS = `local` (no tracker), list drafts under DRAFTS changed on `<DATE>`, plus still-open items (`status: todo` or `in-progress`) as context.

## 4. Harvest vault deltas

Files under DELTAS changed on `<DATE>` (mtime catches uncommitted same-day work):

```bash
find <VAULT>/<each DELTA dir> -name '*.md' \
  -newermt "<DATE> 00:00:00" ! -newermt "<DATE> 23:59:59" 2>/dev/null
```

Cross-check with `git -C <VAULT> log --since="<DATE> 00:00" --until="<DATE> 23:59" --name-status --pretty=format:'%h %s'` for what was committed that day. Summarize: new memories, todos checked off, ideas and drafts added. Skip the daily note itself. If nothing, `_No vault changes._`.

## 5. Harvest Slack (optional, best-effort)

With SLACK = `yes`: my mentions and DMs for the day via the claude.ai Slack connector (load the tools via ToolSearch; Slack search supports `after:`/`before:`). Summarize threads worth remembering as `- **#channel or @person**: topic`. The connector auths interactively and is absent in headless runs; if unavailable, write `_Slack connector unavailable; skipped._` and move on. Don't dump raw messages.

## 6. Write the auto sections (idempotent)

For each harvested source, replace everything between `<!-- auto:X:start -->` and `<!-- auto:X:end -->` (keep the markers) with a `## Heading` and the content. Re-running `/daily` refreshes only these blocks; manual sections are never touched.

## 7. Summary and report

If `## Summary` is still empty (just the comment), draft 1-2 plain lines from the harvest (main thing worked on, anything notable) and leave them for me to edit. Report what was filled and remind me to run `/sync-vault`.
