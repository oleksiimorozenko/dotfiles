# Agent delegation

Default: when a task is research, multi-file scan, or could pull a lot of unrelated content into context, delegate to an agent. Keep the main context focused on what we're actively editing or discussing.

## When to delegate

| Situation | Agent |
|-----------|-------|
| Codebase exploration, "where is X", >3 search queries | `Explore` |
| Open-ended research, multi-step investigation | `general-purpose` |
| Designing an implementation strategy | `Plan` |
| Reviewing the current diff | `code-reviewer` (when present) |
| Claude Code / Claude API / SDK questions | `claude-code-guide` |

## Parallelism

For independent investigations, spawn multiple agents in a single message so they run concurrently. Example: one agent surveys the data layer while another reads the CI config; both report back; I synthesise.

## When NOT to delegate

- The target is already known (a specific file or symbol). Use `Read` or `grep` directly.
- The task is a quick lookup with one or two queries.
- The task requires editing files (agents that lack write access cannot do it, and even those that can lose context coordination).

## Reporting

Ask agents for tight reports (specify a length cap, e.g. "under 200 words"). When I get the result, synthesise into the main thread rather than dumping the agent's output verbatim.
