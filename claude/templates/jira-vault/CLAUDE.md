# CLAUDE.md (template)

Behavioral defaults for Claude in the ticket folder. Fill the context block; org process lives here, out of the shared README.

## Context (fill per vault)

- Tracker: `<Jira Cloud | Azure Boards | none>`
- MCP and ids: `<server name, cloudId or org, board id, custom fields (sprint, story points), JQL quirks>`

## Defaults

- Tracker before files: answer "what am I working on" from the tracker first (when there is one), then reconcile with the local MDs.
- My tickets only: scope queries with `assignee = currentUser()` by default. Broader searches are fine for context, but never list someone else's ticket as my open work, and verify assignee before flagging anything as stale or mine.
- New drafts land in `backlog/`, never directly in a sprint folder.
- After the tracker ticket is created, set the `jira:` frontmatter field. When adding or moving a ticket, keep its `epic:` wikilink intact.
- Ask sprint placement when creating a ticket.
- `<org-specific rules here: unplanned-work prefixes, recurring buckets, retired conventions>`
