---
description: Commit and push the <ctx> Obsidian vault (config, memory, notes)
allowed-tools: Bash(git -C ~/obsidian/<ctx> status:*), Bash(git -C ~/obsidian/<ctx> add:*), Bash(git -C ~/obsidian/<ctx> commit:*), Bash(git -C ~/obsidian/<ctx> pull:*), Bash(git -C ~/obsidian/<ctx> push:*), Bash(git -C ~/obsidian/<ctx> diff:*), Bash(git -C ~/obsidian/<ctx> log:*)
---

<!-- Template: copy to <vault>/_claude/commands/sync-vault.md, replace <ctx>,
     delete this comment. Pair with the carve-out note in _claude/git.md. -->

Sync `~/obsidian/<ctx>` to its git remote. Git is the source of truth. This vault may be committed and pushed without asking each time (vault-only carve-out, documented in `_claude/git.md`); it does not extend to any other repo.

Use `git -C ~/obsidian/<ctx>` for every step (one command each, no `cd`):

1. `git -C ~/obsidian/<ctx> status --short`, plus `diff --stat` when useful. If the tree is clean and there is nothing to pull, say so and stop.
2. `git -C ~/obsidian/<ctx> add -A`.
3. Commit with a one-line conventional message inferred from the change (e.g. `docs(incidents): add ...`, `chore(memory): update ...`). If I passed `$ARGUMENTS`, use that as the message. No `Co-Authored-By` trailer.
4. `git -C ~/obsidian/<ctx> pull --rebase`, then `git -C ~/obsidian/<ctx> push`. On a rebase conflict, stop and surface it rather than forcing anything.
5. Report the short SHA and what synced.
