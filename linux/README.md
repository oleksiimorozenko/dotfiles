# Linux

Two things live here: the **platform differences** between this repo's macOS
and Linux behaviour, and the docs for the `linux/` stow package itself. The
differences are the part you actually need, so they come first.

Written up 2026-08-05 while provisioning a Debian 13 workstation. If you hit a
new divergence, add it here rather than special-casing it in the Brewfile.

---

# Platform differences

## Homebrew on Linux

Homebrew installs to `/home/linuxbrew/.linuxbrew`, not `/opt/homebrew`, and is
not on `PATH` by default:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

Prerequisites before the installer will run:

```bash
sudo apt install -y build-essential procps curl file git
```

**Third-party taps must be trusted before `brew bundle` will load them.**
Homebrew refuses untrusted taps and the bundle aborts on the first one, having
installed nothing:

```bash
brew trust hashicorp/tap
brew trust siderolabs/tap
brew trust oleksiimorozenko/tap
brew trust Azure/kubelogin
```

**Do not mix apt and brew copies of the same tool.** If a tool is in the
Brewfile, purge any apt version first, or you end up with two binaries and
whichever sorts first on `PATH` silently wins.

### Multiple users on one machine

Homebrew on Linux does **not** support multi-user use. The prefix
(`/home/linuxbrew/.linuxbrew`) is owned by whoever installed it. A second user
running `brew install` or `brew bundle` hits `Cellar is not writable` and, worse,
leaves lock/download files it owns in the prefix, which then breaks brew for the
*original* owner too (`chown -R <owner> /home/linuxbrew/.linuxbrew` to recover).

Model that works: **one user owns brew, the rest consume it.** Formulae install
once, into the shared prefix, and land on every user's `PATH` via `brew shellenv`.
So a secondary user's setup:

- runs `make bootstrap` (oh-my-zsh, tpm: per-user) and `make install` (stow: per-user)
- runs `make deps-linux` (apt is system-wide, Claude CLI installs per-user)
- **skips `make deps`** (brew bundle) entirely, since the owner already installed everything

When a secondary user needs a new brew tool, install it *as the owner*. If you'd
rather every user self-serve brew, make the prefix group-writable by a shared
group instead, but Homebrew warns against it and updates can re-break the perms.

## Not available via Homebrew on Linux

### Formulae

| Brewfile entry | Why | Linux install |
|---|---|---|
| `tflint` | Not in homebrew-core for Linux. `terraform-linters/tap` ships it as a **cask**, so it is macOS-only there too | `curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh \| bash` |
| `telnet` | No Linux bottle, so brew would build it from source for no reason | `sudo apt install telnet` |

Those are the only two core formulae in the Brewfile without a usable Linux
build. The other 56 resolve, pulling ~217 packages with dependencies.

### Casks

Casks are a macOS concept, so all of these sit behind `if OS.mac?` in the
Brewfile. Linux equivalents:

| Cask | What | Linux install | Worth it on a remote box? |
|---|---|---|---|
| `claude-code` | Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` (native installer, no Node) | **Yes**, usually the whole point |
| `git-credential-manager` | Git credential helper | `.deb` from `git-ecosystem/git-credential-manager` releases | Only if not using SSH keys |
| `visual-studio-code` | Editor | Microsoft apt repo | Only with a desktop |
| `freelens` | Kubernetes IDE | `.deb` or AppImage from GitHub releases | Only with a desktop |
| `font-jetbrains-mono` | Font | `apt install fonts-jetbrains-mono` | Only with a desktop |
| `ghostty` | Terminal | Not in Debian repos. Community `.deb` (`mkasberg/ghostty-ubuntu`, `dariogriffo/ghostty-debian`), snap, or build from source. In Ubuntu official from 26.04 | No. You connect *from* Ghostty, you do not run it there |
| `medis` | Redis GUI | **No Linux build.** RedisInsight or Another Redis Desktop Manager instead | Substitute only if needed |
| `cmux` | AI agent terminal | **Unverified.** Check upstream before assuming a Linux build exists | Unknown |

## Headless and RDP boxes

- Half the cask list is GUI software. On a machine reached only over SSH, skip
  it. The table's last column is the shortcut.
- Installing a desktop on a **cloud-init VM** pulls in NetworkManager, which
  claims the NIC and runs a **second DHCP client** next to whatever netplan
  already configured, leaving the interface with two leases. Either mark the
  NIC unmanaged in NM or hand networking to NM entirely, but never both.
- Debian cloud images ship almost no locales, so any SSH client forwarding
  `LC_*` triggers `setlocale` warnings on every login. `locale-gen` the one you
  need, or `locales-all` if disk is cheap.
- **xrdp needs an unlocked password.** SSH-key-only users (cloud-init, or any
  `useradd -m` account) have a locked password, so xrdp's PAM auth fails with
  "User does not exist, or could not be authenticated" even though SSH works.
  Fix: `sudo passwd <user>` (sets and unlocks). `passwd -S <user>` shows `P`
  when good, `L` when locked.
- **Cinnamon drops to fallback mode on a GPU-less VM.** No GPU means muffin's
  OpenGL compositor can't start. Force Mesa software rendering in the session:
  `export LIBGL_ALWAYS_SOFTWARE=1` before `exec cinnamon-session` in
  `~/.xsession` (and `/etc/skel`), and ensure `libgl1-mesa-dri` is installed.
- **Claude Code account = the remote Linux user.** An SSH/RDP session runs
  Claude on the remote host and reads that user's `~/.claude`, so the account
  is whichever you logged *that user's* Claude Code into, not your local app's.
  One Linux user per Claude account keeps work and personal cleanly separated.

## Keeping the Brewfile honest

The top-level README claims Linux is fully supported. That only stays true
while the `if OS.mac?` guards hold. When adding a cask or a macOS-only formula:

1. Put it inside an `OS.mac?` block.
2. Add a row above with the Linux equivalent, or an explicit "no Linux build".
3. Sanity check with `ruby -c Brewfile`.

`brew bundle` on Linux is the real test. It fails on the first unavailable
entry and installs nothing, so one unguarded cask breaks the whole bootstrap.

---

# The `linux/` stow package

Linux-specific config files that do not apply to macOS. Currently mostly
placeholders preserving the directory structure.

```
linux/
├── .stow-local-ignore    # Patterns to ignore when stowing
├── README.md             # This file (ignored by stow)
├── .profile              # Shell profile (placeholder)
├── systemd/user/         # User systemd services (future use)
└── config/               # Linux-specific configs (future use)
```

## Installation

Stowed automatically on Linux:

```bash
make install
```

Or manually: `stow linux`.

## Future use

**`systemd/user/`** for user-level services: SSH agent auto-start, environment
setup, background services.

```ini
# systemd/user/ssh-agent.service
[Unit]
Description=SSH Agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
```

**`config/`** for Linux-only application configs: `.xinitrc`, `.xprofile`,
desktop environment settings.

## Adding configs

1. Add files to the right subdirectory.
2. Update `.stow-local-ignore` if a file should not be symlinked.
3. Document it here.
4. Test on a Linux system.

Most configuration is cross-platform and belongs in `zsh/`, `starship/` and the
other shared packages. Only genuinely Linux-only things go here.
