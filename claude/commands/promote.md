---
description: Generalize a skill/command/pattern from the current context into the public dotfiles tier
argument-hint: "<what to promote, e.g. 'the runbook format' or _claude/commands/foo.md>"
---

Take something that proved useful in the current context and land its generic core in the public dotfiles repo, so other contexts can pick it up. Sideways sharing between contexts happens **only** through this flow.

1. Locate the source artifact(s): a command/skill in this vault's `_claude/`, a convention in a vault note, or a pattern the user describes from the current session.
2. Split generic core from context specifics. The public repo's rule (see `claude/README.md`) is absolute: no org or client names, people, emails, account/tenant ids, hostnames, ticket keys, real machine paths, or secrets.
3. Desensitize: replace specifics with `<ctx>`-style placeholders. If a real value isn't yet captured in this vault's `_claude/` section files, move it there now — the generic artifact must be able to find it at `~/.claude/<section>.md` on any machine.
4. Land the generic artifact in `~/git/oleksiimorozenko/dotfiles/claude/`:
   - reusable everywhere as-is → `commands/` or `skills/`
   - per-context starting point that needs `<ctx>` substitution → `templates/` (add the "copy to `<vault>/_claude/...`, replace `<ctx>`, delete this comment" header)
   - behavioral/style rule → merge into `style.md` / `principles.md` / `agents.md`
5. Show the full diff. The dotfiles repo has **no auto-commit carve-out**: propose a conventional commit message and wait for explicit confirmation before committing; never push without being asked.
