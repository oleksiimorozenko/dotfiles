#!/usr/bin/env bash
# ==============================================================================
# Linux extras: everything the Brewfile cannot provide
# ==============================================================================
# Driven by `make deps-linux`. Idempotent, safe to re-run.
#
# The Brewfile covers 56 of 58 formulae on Linux. This handles the rest: the
# two formulae with no Linux build, and the tools that ship as macOS casks and
# therefore need a native package here. See linux/README.md for the reasoning
# behind each entry.
# ==============================================================================
set -euo pipefail

log()  { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is Linux-only. On macOS the Brewfile covers everything." >&2
  exit 1
fi

if ! have apt-get; then
  echo "Only Debian/Ubuntu are handled here. Port the steps for your distro." >&2
  exit 1
fi

sudo apt-get update -qq

# ------------------------------------------------------------------------------
# Formulae with no usable Linux build
# ------------------------------------------------------------------------------
log "telnet (no Linux bottle, brew would build from source)"
sudo apt-get install -y -qq telnet

log "tflint (not in homebrew-core for Linux; the tap ships a cask)"
if ! have tflint; then
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
else
  echo "already installed: $(tflint --version | head -1)"
fi

# ------------------------------------------------------------------------------
# Fonts
# ------------------------------------------------------------------------------
log "JetBrains Mono"
sudo apt-get install -y -qq fonts-jetbrains-mono

# ------------------------------------------------------------------------------
# Terminal
# ------------------------------------------------------------------------------
# Kitty over Alacritty for the graphics protocol (image previews in fzf, etc),
# and it is in Debian proper so there is no third-party repo to maintain.
# Ghostty would match macOS but only via a community .deb.
log "Kitty terminal"
sudo apt-get install -y -qq kitty

# ------------------------------------------------------------------------------
# Claude Code: CLI and desktop app
# ------------------------------------------------------------------------------
log "Claude Code CLI"
# The installer puts it in ~/.local/bin, which is not on PATH in a
# non-interactive shell, so `have claude` alone would reinstall every run.
if have claude; then
  echo "already installed: $(claude --version)"
elif [[ -x "$HOME/.local/bin/claude" ]]; then
  echo "already installed: $("$HOME/.local/bin/claude" --version)"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi

log "Claude Desktop (Linux beta; Debian 12+ / Ubuntu 22.04+)"
if ! have claude-desktop; then
  KEYRING=/usr/share/keyrings/claude-desktop-archive-keyring.asc
  EXPECTED_FP="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
  sudo curl -fsSLo "$KEYRING" https://downloads.claude.ai/claude-desktop/key.asc
  FP=$(gpg --show-keys --with-colons "$KEYRING" | awk -F: '/^fpr:/{print $10; exit}')
  if [[ "$FP" != "$EXPECTED_FP" ]]; then
    echo "Signing key fingerprint mismatch. Got $FP, expected $EXPECTED_FP. Aborting." >&2
    sudo rm -f "$KEYRING"
    exit 1
  fi
  echo "deb [arch=amd64,arm64 signed-by=$KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq claude-desktop
else
  echo "already installed"
fi

# ------------------------------------------------------------------------------
# GUI applications (skip on headless boxes)
# ------------------------------------------------------------------------------
if [[ "${SKIP_GUI:-0}" == "1" ]]; then
  log "SKIP_GUI=1, skipping VS Code and Chrome"
else
  log "Visual Studio Code"
  if ! have code; then
    sudo curl -fsSLo /usr/share/keyrings/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft.asc] https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq code
  else
    echo "already installed"
  fi

  log "Google Chrome"
  if ! have google-chrome; then
    sudo curl -fsSLo /usr/share/keyrings/google-chrome.asc https://dl.google.com/linux/linux_signing_key.pub
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.asc] https://dl.google.com/linux/chrome/deb/ stable main" \
      | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq google-chrome-stable
  else
    echo "already installed"
  fi

  # Password managers. Desktop apps for vault management; passkeys are handled
  # by each product's browser extension (installed per browser profile).
  log "1Password (desktop + CLI, apt repo)"
  if ! have 1password; then
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
      | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
      | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
    # 1Password's apt package requires a debsig policy to verify
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
      | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
      | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    sudo apt-get update -qq
    sudo apt-get install -y -qq 1password 1password-cli
  else
    echo "already installed"
  fi

  log "Bitwarden (desktop, Flatpak)"
  if ! flatpak list 2>/dev/null | grep -q com.bitwarden.desktop; then
    sudo apt-get install -y -qq flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y --noninteractive flathub com.bitwarden.desktop
  else
    echo "already installed"
  fi
fi

# ------------------------------------------------------------------------------
# Deliberately not installed
# ------------------------------------------------------------------------------
# git-credential-manager: `gh auth login` already configures a git credential
#   helper for HTTPS remotes, which is how these repos are cloned. GCM ships a
#   .deb if you ever need it standalone, but the two overlap.
# medis: no Linux build. RedisInsight or Another Redis Desktop Manager instead.
# ghostty: community .deb only on Debian. Kitty above covers the need.

log "Done"
echo "Installed outside brew. Re-run any time; every step is idempotent."
