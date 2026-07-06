# Git config layout

How git global config is wired on these machines, and why there is an untracked `~/.gitconfig`.

## Files

- `git/config` (this repo) is symlinked to `~/.config/git/config`. It is the tracked, shared base: aliases, colors, pull/push defaults, and `[include] ~/.config/git/config.local`.
- `~/.config/git/config.local` (untracked, machine-local): `includeIf` directory routing to per-context identity files, plus any machine-specific settings. Start from `config.local.example`.
- `~/.config/git/config.work` and `config.personal` (untracked): per-context `[user]` identity and excludesfile, pulled in by the `includeIf` rules.
- `~/.gitconfig` (untracked): credential / GCM config, and the write-sink for `git config --global` (see below).

Git reads all global-scope files: `~/.config/git/config` (XDG) first, then `~/.gitconfig`. On a conflicting single-valued key, `~/.gitconfig` wins because it is read last. Both are always read, so the XDG config and its includes stay fully in effect.

## Why there is an untracked ~/.gitconfig (the GCM workaround)

Git Credential Manager (and `az`, and interactive `git config --global`) persist config by writing at global scope. With no `~/.gitconfig`, `git config --global` writes to `$XDG_CONFIG_HOME/git/config` (`~/.config/git/config`), which here is a symlink into this repo. So GCM's Azure Repos hints (a `[credential "azrepos:org/..."]` block with `azureAuthority` and `username`) land in the tracked file and surface as an uncommitted repo change every time you authenticate.

Workaround: keep an untracked `~/.gitconfig` present. `git config --global` writes to `~/.gitconfig` whenever it exists (it takes write precedence over the XDG file), so GCM's writes land there, off the tracked config. Nothing is lost because the XDG config and its includes are still read.

Recommended split so there is a single owner per concern:
- `~/.gitconfig`: credential / GCM config. GCM manages the azrepos entries here.
- `~/.config/git/config.local`: `includeIf` routing only.

## New machine

Create a comment-only `~/.gitconfig` before authenticating any Azure Repos remote, so GCM never writes into the symlinked tracked config in the first place.

## Verify

```
# credential config resolves from ~/.gitconfig
git config --show-origin --get-regexp credential

# the tracked base and its includes are still read
git config --show-origin --get-regexp '^alias\.'

# a --global write lands in ~/.gitconfig, not the repo
git config --global test.probe 1 && git config --show-origin --get test.probe && git config --global --unset test.probe
```
