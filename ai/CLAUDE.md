# Global instructions

Index file. `AGENTS.md` holds the shared rules as plain text so any tool can use it; the rest of this file is Claude-only. Public files live in this repo; the private sections are symlinked in from a separate location and no-op on machines where they're absent.

@~/.claude/AGENTS.md

## Claude Code

- The `docstyle-lint` hook enforces the greppable subset of the writing rules (em-dashes, banned phrases, AI-tool fingerprints) on every `.md` write. Treat it as a backstop, not the whole standard.
- When permission prompts keep interrupting a session, suggest running `/fewer-permission-prompts` (it mines transcripts and proposes allowlist additions). Occasionally, not every session.

@~/.claude/delegation.md

## Private (symlinked, not in this repo)

@~/.claude/context.md
@~/.claude/vault.md
@~/.claude/operations.md
@~/.claude/shell.md
@~/.claude/git.md
@~/.claude/projects.md
@~/.claude/mcp.md
@~/.claude/secrets.md
