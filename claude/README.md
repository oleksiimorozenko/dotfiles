# Claude Code config (public)

The shareable part of my Claude Code setup, symlinked into `~/.claude`.

- `CLAUDE.md`: index; imports the section files by absolute path (`@~/.claude/...`)
- `style.md`: communication and writing style
- `principles.md`: working principles (trust but verify, planning, git safety)
- `agents.md`: when and how to delegate to subagents

Private sections (identity, ops, projects, MCP wiring, secrets inventory) live outside this repo and are symlinked into `~/.claude` separately. The imports for them simply no-op on a machine where they're absent, so this repo stands alone.
