# settings.json snippets

`settings.json` stays per-context (it holds machine and org specifics); these are the shared building blocks to copy in. Spell every path with `~`: file rules resolve it against the real home, and Bash rules match literal command text, which our commands always write with `~`.

## Allow: read-only core

Claude Code runs a built-in set of read-only commands without prompting in any mode (`ls`, `cat`, `grep`, `find`, `head`, `tail`, `wc`, `stat`, `du`, `diff`, `sort`, `uniq`, `which`, `pwd`, `cd`, read-only `git` forms, ...). Don't allowlist those. Add the non-builtin tools you actually use, plus the vault git prefix rules for `/sync-vault`:

```json
"allow": [
  "Bash(rg:*)", "Bash(jq:*)", "Bash(yq:*)", "Bash(fd:*)",
  "Bash(tree:*)", "Bash(eza:*)", "Bash(bat:*)",
  "WebSearch", "WebFetch",
  "Read(//tmp/**)", "Read(//private/tmp/**)",
  "Write(//tmp/**)", "Write(//private/tmp/**)",
  "Bash(git -C ~/obsidian/<ctx> status:*)",
  "Bash(git -C ~/obsidian/<ctx> add:*)",
  "Bash(git -C ~/obsidian/<ctx> commit:*)",
  "Bash(git -C ~/obsidian/<ctx> pull:*)",
  "Bash(git -C ~/obsidian/<ctx> push:*)",
  "Bash(git -C ~/obsidian/<ctx> diff:*)",
  "Bash(git -C ~/obsidian/<ctx> log:*)"
]
```

Context-specific tool families (aws, az, kubectl, terraform, helm, gh) stay in each context's own list. When prompts pile up, run `/fewer-permission-prompts` rather than hand-curating.

## Deny: secrets

Private key material and secret stores. Deliberately narrower than `~/.ssh/**`: public keys, `authorized_keys`, `known_hosts`, and `config` stay readable for debugging. A deny rule can't be overridden interactively, only by editing settings.

```json
"deny": [
  "Read(~/.ssh/id_*)",
  "Read(~/**/*.pem)",
  "Read(~/**/*.key)",
  "Read(~/**/*.env)",
  "Read(~/**/secrets/**)",
  "Read(~/.aws/credentials)"
]
```

## Hooks: docstyle

PostToolUse on every .md write (all contexts). PreToolUse on Jira posts (contexts with a Jira MCP); pick the matcher for the server flavor and verify the tool names with `/mcp` before enabling.

```json
"hooks": {
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        { "type": "command",
          "command": "\"$HOME/.claude/hooks/docstyle-lint.sh\"",
          "statusMessage": "docstyle lint" }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "mcp__atlassian__(addCommentToJiraIssue|createJiraIssue|editJiraIssue)",
      "hooks": [
        { "type": "command",
          "command": "\"$HOME/.claude/hooks/docstyle-lint-jira.sh\"",
          "statusMessage": "docstyle lint (jira)" }
      ]
    }
  ]
}
```

Matcher for the official Atlassian server: `mcp__atlassian__(addCommentToJiraIssue|createJiraIssue|editJiraIssue)`. For sooperset/mcp-atlassian: `mcp__atlassian__(jira_add_comment|jira_create_issue|jira_update_issue)`.

## Hooks: SessionEnd nudges

Vault-dirty (all contexts):

```json
{ "type": "command",
  "command": "if [ -n \"$(git -C ~/obsidian/<ctx> status --porcelain 2>/dev/null)\" ]; then echo \"<ctx> vault has uncommitted changes. Run /sync-vault.\"; fi" }
```

Daily-note (work contexts; one `git log` clause per repo that counts as work):

```json
{ "type": "command",
  "command": "D=$(date +%F); if [ ! -f ~/obsidian/<ctx>/daily/$D.md ] && [ -n \"$(git -C ~/git/<org>/<repo> log --all --author=<email> --since=midnight --oneline 2>/dev/null)\" ]; then echo \"You committed today but have no daily note. Run /daily.\"; fi" }
```

## Other shared keys

```json
"autoMemoryDirectory": "~/obsidian/<ctx>/memory"
```

Model, theme, effort level, and notification settings are personal per machine and not standardized.
