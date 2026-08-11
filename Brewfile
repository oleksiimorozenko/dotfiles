# ==============================================================================
# Homebrew dependencies
# ==============================================================================
# This Brewfile manages all system dependencies for the dotfiles repository.
#
# Usage:
#   brew bundle                    # Install everything
#   brew bundle --no-upgrade       # Install without upgrading existing
#   brew bundle cleanup --force    # Remove packages not in this file
#   brew bundle check              # Check if everything is installed
#
# Third-party tap trust (Homebrew 5.1+):
#   Non-official taps are skipped by `brew update` and refused at load time when
#   HOMEBREW_REQUIRE_TAP_TRUST is set. `brew bundle` auto-taps but does NOT trust,
#   so on a fresh machine trust the taps this file relies on (per-machine state,
#   stored in ~/.config/homebrew/trust.json — it cannot live in this Brewfile):
#
#     brew trust hashicorp/tap oleksiimorozenko/tap Azure/kubelogin manaflow-ai/cmux siderolabs/tap
#
#   Do NOT tap derailed/k9s — k9s lives in homebrew-core and the tap only shadows
#   it. Untrusted-tap warnings for taps not listed above come from tools this file
#   does not manage; `brew trust <tap>` to keep them or `brew untap <tap>` to remove.
# ==============================================================================

# ------------------------------------------------------------------------------
# Core Utilities
# ------------------------------------------------------------------------------
brew "stow"                    # Symlink manager (required for dotfiles)
brew "coreutils"               # GNU core utilities

# ------------------------------------------------------------------------------
# Modern CLI Replacements
# ------------------------------------------------------------------------------
brew "bat"                     # Cat with syntax highlighting
brew "eza"                     # Modern ls with colors and git integration
brew "fd"                      # Fast find alternative
brew "ripgrep"                 # Fast grep alternative
brew "zoxide"                  # Smart cd that learns your habits
brew "procs"                   # Modern ps with color and tree view
brew "ncdu"                    # NCurses disk usage analyzer
brew "xh"                      # Friendly HTTP request tool (curl/httpie alternative)

# ------------------------------------------------------------------------------
# Shell & Prompt
# ------------------------------------------------------------------------------
brew "zsh"                     # Z Shell
brew "zsh-autosuggestions"     # Fish-like autosuggestions
brew "starship"                # Cross-shell prompt
brew "fzf"                     # Fuzzy finder

# ------------------------------------------------------------------------------
# Version Control & Git Tools
# ------------------------------------------------------------------------------
brew "git"                     # Version control
brew "git-delta"               # Syntax-highlighting pager for git
if OS.mac?
  cask "git-credential-manager" # Git Credential Manager for secure authentication
end
brew "gh"                      # GitHub CLI
brew "gitleaks"                # Audit git repos for secrets
brew "bitwarden-cli"           # Bitwarden vault CLI (secrets retrieval; desktop app is separate)
brew "act"                     # Run GitHub Actions locally
brew "action-validator"        # Validate GitHub Action YAML files
brew "pre-commit"              # Git hooks framework

# ------------------------------------------------------------------------------
# Security & Encryption
# ------------------------------------------------------------------------------
brew "gnupg"                   # GNU Pretty Good Privacy (PGP)

# ------------------------------------------------------------------------------
# Editors & Terminal Tools
# ------------------------------------------------------------------------------
brew "tmux"                    # Terminal multiplexer
brew "nano"                    # Simple text editor
brew "neovim"                  # Modern vim
brew "midnight-commander"      # Terminal file manager

# ------------------------------------------------------------------------------
# Development Utilities
# ------------------------------------------------------------------------------
brew "tree"                    # Directory visualization
brew "htop"                    # Interactive process viewer
brew "jq"                      # JSON processor
brew "yq"                      # YAML processor
brew "yamllint"                # YAML linter
brew "glow"                    # Markdown renderer for terminal
brew "watch"                   # Execute program periodically

# ------------------------------------------------------------------------------
# Network Tools
# ------------------------------------------------------------------------------
brew "wget"                    # Internet file retriever
if OS.mac?
  brew "telnet"                # No Linux bottle; `apt install telnet` there
end
brew "arping"                  # Check MAC addresses on LAN
brew "ipcalc"                  # IP network calculator
brew "pssh"                    # Parallel SSH

# ------------------------------------------------------------------------------
# Language Runtimes & Package Managers
# ------------------------------------------------------------------------------
# Python
brew "uv"                      # Fast Python package manager
# brew "pyenv"                 # Python version management

# Node.js
brew "node"                    # Node.js runtime
# brew "nvm"                   # Node version management

# Ruby
brew "rbenv"                   # Ruby version manager
# brew "ruby-build"            # Install Ruby versions

# Rust
brew "rustup"                  # Rust toolchain installer

# ------------------------------------------------------------------------------
# Infrastructure as Code (IaC)
# ------------------------------------------------------------------------------
# Ansible
brew "ansible"                 # Configuration management

# Terraform ecosystem
brew "hashicorp/tap/terraform" # Infrastructure as Code (tap needs `brew trust`; removed from core under BUSL)
# brew "terragrunt"            # Terraform wrapper
if OS.mac?
  brew "tflint"                # Terraform linter (macOS only on brew: not in
                               # homebrew-core for Linux, and terraform-linters/tap
                               # ships it as a cask. On Linux install via the
                               # upstream script instead.)
end
brew "tfsec"                   # Terraform security scanner
brew "terraform-docs"          # Generate Terraform documentation
brew "terracognita"            # Import existing infra to Terraform
brew "terraformer"             # Generate Terraform from existing infra
brew "iam-policy-json-to-terraform"  # Convert IAM policies to Terraform

# ------------------------------------------------------------------------------
# Kubernetes
# ------------------------------------------------------------------------------
brew "kubernetes-cli"          # kubectl
brew "kubectx"                 # Switch contexts/namespaces easily
brew "helm"                    # Kubernetes package manager
brew "k9s"                     # Kubernetes TUI
brew "argocd"                  # GitOps CD for Kubernetes
brew "chart-testing"           # Helm chart testing and linting
tap "siderolabs/tap"           # needs `brew trust`
brew "siderolabs/tap/talosctl" # Talos Linux Kubernetes CLI

# ------------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------------
tap "oleksiimorozenko/tap"          # needs `brew trust` (personal tap)
brew "oleksiimorozenko/tap/awsom"  # k9s-like TUI for AWS SSO
brew "awscli"                       # AWS CLI v2

# ------------------------------------------------------------------------------
# Azure
# ------------------------------------------------------------------------------
brew "azure-cli"               # Azure command-line interface
tap "Azure/kubelogin"               # needs `brew trust`
brew "Azure/kubelogin/kubelogin"  # Kubernetes login for Azure

# ------------------------------------------------------------------------------
# Containers & VMs
# ------------------------------------------------------------------------------
brew "dive"                    # Explore Docker image layers
brew "lima"                    # Linux virtual machines
# cask "docker"                # Docker Desktop

# ------------------------------------------------------------------------------
# Databases
# ------------------------------------------------------------------------------
brew "redis"                   # In-memory data store

# ------------------------------------------------------------------------------
# Agent / session runtime
# ------------------------------------------------------------------------------
brew "herdr"                   # Keeps coding-agent (Claude Code) sessions alive across
                               # disconnects; detach/reattach from any machine. Per-user server.

# ------------------------------------------------------------------------------
# Input automation (mouse/keyboard)
# ------------------------------------------------------------------------------
if OS.mac?
  brew "cliclick"              # macOS mouse/keyboard automation (used by ol.sh
                               # keep-awake nudge). Linux equivalent is xdotool,
                               # installed via deps-linux.
end

# ------------------------------------------------------------------------------
# Fun
# ------------------------------------------------------------------------------
brew "cowsay"                  # Configurable talking cow

# ==============================================================================
# macOS only
# ==============================================================================
# Casks, fonts and Mac App Store entries are macOS concepts. Without this
# guard `brew bundle` aborts on Linux, which is why the "Linux fully
# supported" claim in the README stopped being true once casks were added.
if OS.mac?
  # ----------------------------------------------------------------------------
  # GUI Applications (Casks)
  # ----------------------------------------------------------------------------
  # Terminal
  cask "ghostty"                 # GPU-accelerated terminal
  tap "manaflow-ai/cmux"         # needs `brew trust`
  cask "cmux"                    # AI agent terminal with vertical tabs

  # AI Assistant Tools
  cask "claude-code"             # Terminal-based AI coding assistant

  # Databases
  cask "medis"                   # Modern Redis GUI

  # Kubernetes
  cask "freelens"                # Kubernetes IDE

  # Browsers
  # cask "firefox"
  # cask "google-chrome"

  # Editors
  cask "visual-studio-code"

  # Productivity
  # cask "rectangle"             # Window management
  # cask "maccy"                 # Clipboard manager

  # ----------------------------------------------------------------------------
  # Fonts
  # ----------------------------------------------------------------------------
  cask "font-jetbrains-mono"     # Monospace font with ligatures

  # ----------------------------------------------------------------------------
  # Mac App Store (requires `mas` CLI)
  # ----------------------------------------------------------------------------
  # mas "Xcode", id: 497799835
  # mas "Keynote", id: 409183694
  # mas "Pages", id: 409201541
  # mas "Numbers", id: 409203825
end
