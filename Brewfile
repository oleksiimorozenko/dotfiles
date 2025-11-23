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
brew "gh"                      # GitHub CLI
brew "gitleaks"                # Audit git repos for secrets
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
brew "telnet"                  # TELNET client
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
# brew "terraform"             # Infrastructure as Code
# brew "terragrunt"            # Terraform wrapper
brew "tflint"                  # Terraform linter
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

# ------------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------------
tap "oleksiimorozenko/tap"
brew "oleksiimorozenko/tap/awsom"  # k9s-like TUI for AWS SSO

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
# Fun
# ------------------------------------------------------------------------------
brew "cowsay"                  # Configurable talking cow

# ------------------------------------------------------------------------------
# GUI Applications (Casks)
# ------------------------------------------------------------------------------
# Terminal
cask "ghostty"                 # GPU-accelerated terminal

# Databases
cask "medis"                   # Modern Redis GUI

# Kubernetes
cask "openlens"                # Kubernetes IDE

# Browsers
# cask "firefox"
# cask "google-chrome"

# Editors
# cask "visual-studio-code"

# Productivity
# cask "rectangle"             # Window management
# cask "maccy"                 # Clipboard manager

# ------------------------------------------------------------------------------
# Fonts
# ------------------------------------------------------------------------------
cask "font-jetbrains-mono"     # Monospace font with ligatures

# ------------------------------------------------------------------------------
# Mac App Store (requires `mas` CLI)
# ------------------------------------------------------------------------------
# mas "Xcode", id: 497799835
# mas "Keynote", id: 409183694
# mas "Pages", id: 409201541
# mas "Numbers", id: 409203825
