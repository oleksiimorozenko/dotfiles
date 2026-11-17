# Global instructions

Index file. `AGENTS.md` holds the shared rules as plain text so any tool can use it; the rest of this file is Claude-only. Public files live in this repo; the private sections are symlinked in from a separate location and no-op on machines where they're absent.

@~/.claude/AGENTS.md

## Claude Code

- The `docstyle-lint` hook enforces the greppable subset of the writing rules (em-dashes, banned phrases, AI-tool fingerprints) on every `.md` write. Treat it as a backstop, not the whole standard.
- When permission prompts keep interrupting a session, suggest running `/fewer-permission-prompts` (it mines transcripts and proposes allowlist additions). Occasionally, not every session.
- Claude Code resolves four settings files: user (`~/.claude/settings.json`), project (`<root>/.claude/settings.json`), local (`<root>/.claude/settings.local.json`) and managed policy. There is no user-level `.local` file: `~/.claude/settings.local.json` loads only when a session's project root is the home directory. Put global settings in `~/.claude/settings.json`, and check a hook runs with a sentinel hook, not by reading config.

@~/.claude/delegation.md

## Private (symlinked, not in this repo)

@~/.claude/context.md
@~/.claude/vault.md
@~/.claude/operations.md
@~/.claude/shell.md
@~/.claude/git.md
@~/.claude/projects.md
@~/.claude/tools.md
@~/.claude/secrets.md
