# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

This file covers architecture, invariants, and the traps that are not obvious from reading the tree. It deliberately does not restate content that lives in a file of its own. For package inventories read the `Brewfile`, for macOS defaults read `macos/settings.sh`, for the full keybinding reference read `tmux/README.md`, and for the Claude config tiers read `claude/README.md`. Those files are the source of truth; duplicating them here is how documentation goes stale.

## Repository overview

Personal dotfiles managed with GNU Stow and XDG Base Directory layout. Packages symlink into `~/.config`, except `home/`, which targets `~/`.

Supported: macOS (Sonoma and later) and Linux (Ubuntu 22.04 and later). Windows is not supported.

## Where the clone lives

Assume the clone lives at `~/git/<user>/dotfiles`.

This is a convention the repo depends on, not a preference. `zsh/zsh.d/68-herdr.zsh:12` guards on an absolute path and `zsh/zsh.d/68-herdr.zsh:13` exports the same path as `HERDR_CONFIG_PATH`. Both must name a file that exists, or the guard fails silently and herdr falls back to `~/.config/herdr/config.toml`. The commands in `claude/commands/lint-vault.md:10` and `claude/commands/promote.md:11` also spell the path out, because prose instructions cannot resolve it at runtime.

Moving the clone breaks every symlink at once. See the repair sequence below.

## Three wiring systems

The single most common source of confusion: this repo installs into three places by two different mechanisms, and only two of them are part of `make install`.

| Target | Mechanism | Command |
|---|---|---|
| `~/.config` | `stow --ignore=home .` (via `.stowrc`) | `make install`, `make restow` |
| `~/` | `stow --dir=. --target=$HOME home` | `make install`, `make restow` |
| `~/.claude` | `claude/bin/bootstrap.sh` | `make claude` |

`~/.claude` is not a stow target. It is built by `claude/bin/bootstrap.sh`, which links the public tier from this repo and the private tier from a context vault. It is excluded from `make install` on purpose: the script resolves and enters `VAULT`, so it would fail on a machine without one.

`bootstrap.sh` derives its own repo root from `${BASH_SOURCE[0]}` and writes absolute symlinks with `ln -sfn`, so it self-heals on re-run and never conflicts.

### Repairing after the clone moves

Three steps, in order. `make restow` alone is not enough and will abort: stow only reclaims links that point into its own stow directory, so links aimed at the old path are treated as foreign and refused.

```bash
make clean    # delete dead links under ~/.config and ~ (maxdepth 1)
make restow   # re-link ~/.config and $HOME
make claude   # re-link ~/.claude (reads VAULT from vault.local.mk)
```

Then verify nothing dangles:

```bash
find ~/.config ~/.claude -type l ! -exec test -e {} \; -print
```

`make claude` relinks, but it does not remove links to files that were deleted from the repo. `make clean` does not reach `~/.claude`, which sits below its search depth.

## Stow architecture

`.stowrc` sets `--target=~/.config`, `--no-folding`, and a list of ignore patterns.

`--no-folding` keeps real directories and links individual files, so a package can coexist with tool-generated files in the same directory.

`home/` must be stowed first and separately with `-t ~`, because it provides `~/.zshenv`, which sets `ZDOTDIR` and bootstraps everything else. `make install` already does this in the right order; manual stow runs must do the same.

Two things to know about the ignore patterns:

- Patterns are anchored regexes matched against each path segment, without a trailing slash. `--ignore=macos/` therefore never matches, and `macos/settings.sh` is stowed to `~/.config/macos/settings.sh` despite the entry.
- `--ignore=.*\.example$` does work, which is why `zsh/local/.zshrc.local.example` stays unstowed.

Running bare `stow <package>` is not equivalent to `make install`. The Makefile stows the repo root as a single package, giving `~/.config/zsh/.zshrc`. A bare `stow zsh` stows the package contents instead, giving `~/.config/.zshrc` and `~/.config/zsh.d/`. Mixing the two leaves a stale duplicate tree. Use `make restow`.

## ZSH loading chain

1. `~/.zshenv` (from `home/.zshenv`) sets `ZDOTDIR=$XDG_CONFIG_HOME/zsh`
2. `~/.config/zsh/.zshrc` sources every module
3. `~/.config/zsh/zsh.d/*.zsh` loads in numeric order
4. `~/.config/zsh/local/local.zsh` (optional, gitignored) loads last

Modules:

| Module | Purpose |
|---|---|
| `00-exports.zsh` | Environment variables (XDG, defaults) |
| `05-os-detection.zsh` | Sets `$DOTFILES_OS` |
| `10-paths.zsh` | PATH, Homebrew shellenv |
| `20-editor.zsh` | Editor selection |
| `30-omz.zsh` | Oh-My-Zsh init |
| `40-plugins.zsh` | Plugin list (fzf-tab must be first) |
| `50-aliases.zsh` | Aliases, including platform-specific ones |
| `60-functions.zsh` | `cx`, `fcd`, `pyclean` |
| `65-aws-helpers.zsh` | `awsp`, `awswho`, `awslogin` |
| `66-azure-helpers.zsh` | Azure helpers |
| `67-tailscale-helpers.zsh` | Tailscale helpers |
| `68-herdr.zsh` | Exports `HERDR_CONFIG_PATH` |
| `70-app-settings.zsh` | Per-application settings and tmux aliases |
| `75-fzf.zsh` | fzf options, theme, key bindings |
| `76-zoxide.zsh` | zoxide init |
| `80-completions.zsh` | Completion styles |
| `85-fzf-completions.zsh` | fzf-tab previews |
| `90-misc.zsh` | Everything else |

Numeric prefixes give a deterministic order. `05` runs early so `$DOTFILES_OS` is set for everything after it.

## Packages

`bat`, `claude`, `eza`, `ghostty`, `git`, `glow`, `herdr`, `linux`, `macos`, `nano`, `obsidian`, `starship`, `tmux`, `zsh`, plus `home` (targets `~/`).

Several carry their own `README.md`; read it before changing the package.

## Make targets

| Target | Effect |
|---|---|
| `prereq-check` / `prereq-install` | Verify or install git, zsh, curl |
| `bootstrap` | Homebrew, Oh-My-Zsh, fzf-tab, TPM |
| `deps` | `brew bundle` |
| `deps-linux` | What the Brewfile cannot supply on Linux |
| `claude` | Wire `~/.claude` from this repo and `VAULT` |
| `install` / `uninstall` | Stow or unstow `home` and the rest |
| `restow` | Re-apply after edits |
| `clean` | Delete dead symlinks under `~/.config` and `~` |
| `list` | List packages |

`make claude` needs `VAULT`. Set it once in `vault.local.mk` (gitignored) rather than passing it each run. The Makefile ships no default on purpose, since this repo is public and must not name a vault.

## Coding standards

### Positive if-block pattern

Guard optional dependencies with a positive `if`, never an early return.

```zsh
# Good
if command -v fzf &> /dev/null; then
  export FZF_DEFAULT_OPTS="..."
fi

# Bad: the return value leaks and shows an error indicator in the prompt
if ! command -v fzf &> /dev/null; then
  return 0
fi
```

An early return leaves a non-zero exit status that Starship renders as a failure marker after `reload`.

For functions that need a tool, keep the positive guard and give a real error:

```zsh
pyclean() {
  if command -v fd &> /dev/null; then
    fd -I -H '...' --exec rm -rf {} \;
  else
    echo "Error: 'fd' is required. Install with: brew install fd"
    return 1
  fi
}
```

### OS detection

Use `$DOTFILES_OS` (`macos`, `linux`, or `unknown`), set once in `zsh/zsh.d/05-os-detection.zsh`. Do not test `$OSTYPE` directly in aliases or functions.

```zsh
if [[ "$DOTFILES_OS" == "macos" ]]; then
    alias afk='pmset displaysleepnow'
elif [[ "$DOTFILES_OS" == "linux" ]]; then
    alias afk='loginctl lock-session'
fi
```

`pubkey`, `afk`, and `flushdns` are the aliases with platform-specific bodies. The Linux clipboard path picks `xclip` or `wl-copy` by probing for each.

### Paths in committed files

Write `~`-relative paths in configs, commands, and docs, and `$HOME` in scripts. Never a literal `/Users/<name>`. Permission rules resolve `~` against the real home and Bash rules match literal command text, so the allowlist only holds across machines if the text uses `~`. This mirrors the rule in `claude/README.md`.

## Local overrides

| File | Purpose |
|---|---|
| `~/.config/zsh/local/local.zsh` | Machine-specific shell config, loaded last |
| `~/.config/git/config.local` | User identity, included by `git/config` |
| `vault.local.mk` | Sets `VAULT` for `make claude` |

All three are gitignored. Nothing context-identifying belongs in a tracked file.

## Tool notes

Only the parts that have bitten before. Per-package READMEs carry the rest.

**Homebrew on both platforms.** Same package names and versions, one Brewfile. macOS installs to `/opt/homebrew` or `/usr/local`, Linux to `/home/linuxbrew/.linuxbrew`. On Linux, add `brew shellenv` to `~/.profile` after `make bootstrap`.

**Starship** (`starship/starship.toml`). Three formats ship in the file; exactly one is uncommented. Alignment uses the `$fill` module with `right_format = ""`, because `right_format` renders on the last line when `$line_break` is in play. Literal parentheses need double-escaping (`[\\(]`, `[\\)]`). Square brackets cannot be escaped inside `git_status` format strings, so use other characters there. Colors come from the `catppuccin_mocha` palette by name. Kubernetes contexts are always shown and color-coded by environment, which is a safety feature: production reads red.

**Ghostty** (`ghostty/config`). `shell-integration-features` overrides `cursor-style`. To keep a custom cursor, leave `cursor` out of that list. `ssh-terminfo` opens a second SSH connection to install terminfo and misbehaves against hosts without `tic`; `command ssh <host>` bypasses the wrapper.

**herdr** (`herdr/config.toml`). Stowing into `~/.config/herdr` does not survive, because herdr owns that directory as its runtime dir and rewrites files there. The config is therefore pointed at by `HERDR_CONFIG_PATH` instead. With `herdr --remote`, keybindings default to the client machine's config (`--remote-keybindings local`), so the local file governs a remote attach. Validate with `herdr config check`; apply to a running server with `herdr server reload-config`. Unset keys inherit herdr's defaults, which `herdr --default-config` prints.

**git-delta** (`git/config`). Use `syntax-theme = base16`; `Catppuccin-mocha` is not a built-in delta theme and warns. Catppuccin colors are applied through `minus-style` and `plus-style`.

**fzf-tab.** Must be the first entry in the plugin list in `zsh/zsh.d/40-plugins.zsh`, and must be cloned into `~/.oh-my-zsh/custom/plugins/fzf-tab` (done by `make bootstrap`).

**tmux sessions** (`tmux/bin/`). Plain shell scripts, not tmuxp: `tmux-init` and `tmux-init-fresh`. The `-fresh` variant kills the session and clears `~/.local/share/tmux/resurrect/last` first, because tmux-resurrect restores the old layout over a new one. `tmux/bin` is added to PATH in `zsh/zsh.d/10-paths.zsh`; aliases live in `zsh/zsh.d/70-app-settings.zsh`.

## Common pitfalls

1. `make restow` after moving the clone aborts with "existing target is not owned by stow". Run `make clean` first, then `make restow`, then `make claude`.
2. Hooks and commands under `~/.claude` still point at the old path after a move. `make restow` does not touch them; `make claude` does.
3. `make clean` must not use `find -xtype l`. That primary is GNU-only and BSD find on macOS rejects it, which silently turns the target into a no-op. The portable form is `-type l ! -exec test -e {} \;`.
4. A new module in `zsh/zsh.d/` needs `make restow` before `reload` will see it.
5. An `x` error indicator after `reload` usually means an early-return guard in a module. Convert it to a positive if-block.
6. Oh-My-Zsh must exist before `make install`, or the shell config fails to load.
7. `AWS_PROFILE` drives the Starship AWS segment. Use `awsp` from `zsh/zsh.d/65-aws-helpers.zsh`, which is auto-loaded like any other numbered module.
8. Kubernetes context missing from the prompt means a detection condition got uncommented. The config shows it unconditionally by design.
9. Extra spaces between prompt segments come from stacked module spacing. `git_status` supplies the space when present via `( [$all_status]($style))`; `git_branch` has no trailing space and `time` no leading space.
10. `pyclean` needs `fd`.
11. Some `macos/settings.sh` changes need a logout or restart. The script restarts Dock and Finder, but not the system.
12. Tab completion hides dotfiles unless `zstyle ':completion:*' special-dirs true` is set in `zsh/zsh.d/80-completions.zsh`.

## Development workflow

1. Edit files in the repository, never the symlinks in `~/.config`.
2. `make restow` if you added or renamed a file.
3. `exec zsh` or `reload`.
4. Test, then commit.

Adding a package: create the directory, add files, run `make restow`, and confirm the links landed where you expected.

Testing Starship changes: `starship config` validates, `starship print-config` shows the active config, and `starship timings` profiles it.
