# Dotfiles

Personal dotfiles managed with GNU Stow and XDG Base Directory compliance.

## Table of Contents

- [Platform Support](#platform-support)
- [Features](#features)
- [Quick Start](#quick-start)
  - [macOS](#quick-start-macos)
  - [Linux](#quick-start-linux)
- [Prerequisites](#prerequisites)
  - [macOS Prerequisites](#macos-prerequisites)
  - [Linux Prerequisites](#linux-prerequisites)
- [Installation](#installation)
- [Package Structure](#package-structure)
- [Features](#features-1)
  - [fzf - Fuzzy Finding](#fzf---fuzzy-finding-everywhere)
  - [zoxide - Smart Directory Jumping](#zoxide---smart-directory-jumping)
  - [Git Enhancements](#git-enhancements)
  - [Shell Functions & Aliases](#shell-functions--aliases)
- [Customization](#customization)
- [macOS Configuration](#macos-configuration)
- [Linux Notes](#linux-notes)
- [Troubleshooting](#troubleshooting)

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS    | ✅ Fully Supported | Tested on macOS Sonoma+ |
| Linux    | ✅ Fully Supported | Tested on Ubuntu 22.04+ |
| Windows  | ❌ Not Supported | No WSL support planned |

**Cross-platform features:**
- All core configurations work identically on macOS and Linux
- Platform-specific aliases automatically adapt (clipboard, screen lock, DNS flush)
- Same package manager (Homebrew) on both platforms for consistency
- XDG Base Directory compliance (native Linux standard, works on macOS)

## Features

- 🗂️ **XDG Compliant**: All configs under `~/.config/`
- 🔗 **GNU Stow**: Simple symlink management via `.stowrc`
- 🧩 **Modular**: Easy to enable/disable components
- 🚀 **Modern Tools**: eza, bat, starship, fzf, ghostty
- 🎨 **Catppuccin Mocha**: Consistent theming across all tools
- 🔧 **Oh-My-Zsh**: Extensive plugin support
- ⚡ **Starship Prompt**: Two-line prompt with left/right alignment, bold fonts, DevOps features
- 🔍 **fzf Integration**: Fuzzy finding with tab completion previews
- 🚀 **zoxide**: Smart directory jumping
- 📝 **Enhanced Nano**: Better keybindings and syntax highlighting
- 🎨 **git-delta**: Beautiful syntax-highlighted git diffs

## Quick Start

### Quick Start: macOS

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/git/root/dotfiles
cd ~/git/root/dotfiles

# Bootstrap: Install Homebrew, Oh-My-Zsh, and fzf-tab plugin
make bootstrap

# Install dependencies from Brewfile
make deps

# Install dotfiles
make install

# Configure macOS (optional, review first!)
./macos/settings.sh
```

### Quick Start: Linux

```bash
# Install prerequisites (git, zsh, curl)
make prereq-install

# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/git/root/dotfiles
cd ~/git/root/dotfiles

# Bootstrap: Install Homebrew, Oh-My-Zsh, and fzf-tab plugin
make bootstrap

# IMPORTANT: Add Homebrew to PATH (if not already done)
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install dependencies from Brewfile
make deps

# Install dotfiles
make install
```

## Prerequisites

### macOS Prerequisites

- macOS (tested on macOS Sonoma+)
- Command Line Tools for Xcode (provides `git` and `make`)

```bash
# Install Command Line Tools
xcode-select --install
```

**Note:** Homebrew, Oh-My-Zsh, and fzf-tab are automatically installed by `make bootstrap`

### Linux Prerequisites

**Automatically installed:**
```bash
make prereq-install
```

This installs:
- `git` - Version control
- `zsh` - Z Shell
- `curl` - For downloading installers

**Manual installation (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y git zsh curl
```

**Manual installation (Fedora/RHEL):**
```bash
sudo dnf install -y git zsh curl
```

**Manual installation (Arch):**
```bash
sudo pacman -S --noconfirm git zsh curl
```

**Note:** Homebrew, Oh-My-Zsh, fzf-tab, and all other tools are automatically installed by `make bootstrap` and `make deps`

## Installation

### 1. Bootstrap Environment

Install Homebrew, Oh-My-Zsh, and fzf-tab plugin:

```bash
make bootstrap
```

This will:
- Install Homebrew (if not already installed)
- Install Oh-My-Zsh (if not already installed)
- Clone the fzf-tab plugin for Oh-My-Zsh

### 2. Install Dependencies

Install all tools from `Brewfile`:

```bash
make deps
```

**Key tools installed:**
- `stow` - Symlink manager
- `eza`, `bat`, `fd`, `ripgrep` - Modern CLI tools
- `fzf`, `zoxide` - Navigation tools
- `starship` - Cross-shell prompt
- `git-delta` - Beautiful git diffs
- `tmux`, `nano` - Terminal tools

**Manual options:**
```bash
# Install without upgrading existing packages
brew bundle --no-upgrade

# Install specific types only
brew bundle --file=Brewfile --include="brew"  # Only CLI tools
brew bundle --file=Brewfile --include="cask"  # Only GUI apps
```

### 3. Install Dotfiles

The `Makefile` handles installation in the correct order:

```bash
# Install everything (recommended)
make install

# Or install specific packages
stow zsh starship git

# Remove dotfiles
make uninstall

# Reapply after changes
make restow
```

**Installation order:**
1. `home/` package → `~/` (contains `.zshenv`)
2. All other packages → `~/.config/`

### 4. Configure Git Identity

Create `~/.config/git/config.local`:

```gitconfig
[user]
    name = Your Name
    email = your.email@example.com
```

**Tip:** See `git/config.local.example` for advanced configuration including per-directory user settings (useful for separating work and personal projects).

### 5. Reload Shell

```bash
reload  # or: exec zsh
```

## Package Structure

Each directory is a **stow package** that can be installed independently:

| Package | Description | Target | Platform |
|---------|-------------|--------|----------|
| `home/` | Bootstrap files (`.zshenv`) | `~/` | All |
| `zsh/` | ZSH configuration | `~/.config/zsh/` | All |
| `starship/` | Prompt configuration | `~/.config/starship/` | All |
| `git/` | Git config and ignore | `~/.config/git/` | All |
| `ghostty/` | Terminal emulator | `~/.config/ghostty/` | All |
| `tmux/` | Terminal multiplexer | `~/.config/tmux/` | All |
| `bat/` | Syntax highlighter | `~/.config/bat/` | All |
| `eza/` | Modern ls | `~/.config/eza/` | All |
| `nano/` | Text editor | `~/` | All |
| `linux/` | Linux-specific configs (minimal) | `~/.config/linux/` | Linux only |
| `macos/` | macOS settings script (not stowed) | N/A | macOS only |

## Features

### fzf - Fuzzy Finding Everywhere

**Tab Completion with Previews:**
```bash
ls <TAB>      # Shows files with bat preview
cd <TAB>      # Shows directories with tree preview
kill <TAB>    # Shows process info
man <TAB>     # Shows man page preview
```

**Keybindings:**
- `Ctrl+T` - Fuzzy find files
- `Ctrl+R` - Fuzzy find command history
- `Alt+C` - Fuzzy find and cd to directory
- `Ctrl+H` - Toggle preview window

### zoxide - Smart Directory Jumping

```bash
z dotfiles    # Jump to ~/git/root/dotfiles
z api         # Jump to most frecent directory matching "api"
zi            # Interactive directory selection with fzf
```

### Git Enhancements

**Beautiful Diffs:**
```bash
git diff      # Syntax-highlighted with git-delta
git log -p    # Pretty commit history with diffs
```

**Useful Aliases:**
```bash
git main      # Checkout main or master (whichever exists)
git publish   # Push current branch and set upstream
git patch     # Non-paged diff output
git prune-branches  # Remove local branches deleted on remote
```

### Shell Functions & Aliases

**Functions:**
- `cx <dir>` - cd and list
- `fcd` - Fuzzy find directory and cd
- `pyclean` - Remove Python cache files recursively
- `mkcd <dir>` - Make directory and cd (from Oh-My-Zsh)

**Aliases:**
- `l` - Quick detailed listing with full paths
- `reload` - Reload ZSH configuration
- `pubkey` - Copy SSH public key to clipboard
- `afk` - Lock screen immediately

### Tmux - Terminal Multiplexer

**Key Features:**
- **Prefix key:** `Ctrl-a` (instead of default `Ctrl-b`)
- **Catppuccin Mocha theme:** Consistent with other tools
- **Mouse support:** Enabled for scrolling and pane selection
- **Cross-platform clipboard:** Works on both macOS and Linux
- **Large scrollback:** 100M lines of history
- **Vim-style navigation:** Use `hjkl` to switch panes (via tmux-pain-control)

**Key Bindings:**
```bash
Ctrl-a |          # Split pane horizontally
Ctrl-a -          # Split pane vertically
Ctrl-a h/j/k/l    # Navigate panes (vim-style)
Ctrl+Alt-Arrow    # Navigate panes (no prefix needed)
Ctrl-a H/J/K/L    # Resize panes
Ctrl-a r          # Reload tmux config
```

**Copy Mode (Vim-style):**
```bash
Ctrl-a [        # Enter copy mode
v               # Begin selection
y               # Copy selection
q               # Exit copy mode
```

**Plugins (enabled by default):**
- `tmux-pain-control` - Standard pane navigation keybindings
- `tmux-resurrect` - Save and restore tmux sessions
- `tmux-continuum` - Automatic session saving
- `tmux-yank` - Better clipboard integration
- `tmux-thumbs` - Vimium-style quick copy
- `tmux-fzf` - fzf integration for tmux

**TPM (Tmux Plugin Manager):**
- Automatically installed via `make bootstrap`
- Install new plugins: `prefix + I` (Ctrl-a + Shift-I)
- Update plugins: `prefix + U`

📖 **See [tmux/README.md](tmux/README.md) for complete keybinding reference**

## Customization

### Local Overrides

Create machine-specific configurations that won't be committed:

**ZSH:**
```bash
~/.config/zsh/local/local.zsh
```

**Git:**
```bash
~/.config/git/config.local
```

See `git/config.local.example` for a comprehensive template including:
- Basic user identity (name, email)
- Per-directory configuration using `includeIf` (work vs personal projects)
- GPG signing settings
- Custom SSH keys per organization

Example per-directory setup:
```gitconfig
# In ~/.config/git/config.local
[includeIf "gitdir:~/work/"]
    path = ~/.config/git/config.work

# In ~/.config/git/config.work
[user]
    name = Work Name
    email = work@company.com
```

### ZSH Module Loading

Files in `zsh/zsh.d/` load in numerical order:
- `00-exports.zsh` - Environment variables
- `10-paths.zsh` - PATH configuration
- `30-omz.zsh` - Oh-My-Zsh settings
- `40-plugins.zsh` - Plugin list
- `50-aliases.zsh` - Command shortcuts
- `60-functions.zsh` - Shell functions
- `75-fzf.zsh` - fzf configuration
- `76-zoxide.zsh` - zoxide configuration
- `80-completions.zsh` - Custom completions
- `85-fzf-completions.zsh` - fzf-tab previews

## macOS Configuration

The `macos/settings.sh` script automates system preferences:

```bash
./macos/settings.sh
```

**Configures:**
- Dock (size, autohide, hot corners)
- Finder (show hidden files, extensions, path bar)
- Keyboard & Mouse (key repeat, trackpad)
- Screenshots (location, format)
- Safari, Activity Monitor, Terminal

**⚠️ Review the script before running!** Some settings require logout/restart.

## Linux Notes

### Clipboard Support

Platform-specific clipboard commands are automatically configured:

**X11 (most Linux desktops):**
```bash
sudo apt install xclip  # Ubuntu/Debian
# Or: sudo dnf install xclip  # Fedora
# Or: sudo pacman -S xclip    # Arch
```

**Wayland (modern Ubuntu, Fedora):**
```bash
sudo apt install wl-clipboard  # Ubuntu/Debian
# Or: sudo dnf install wl-clipboard  # Fedora
# Or: sudo pacman -S wl-clipboard    # Arch
```

The `pubkey` alias automatically detects and uses the correct tool.

### Homebrew on Linux

This repository uses Homebrew on Linux for consistency with macOS. Benefits:
- Same package names across platforms
- Same versions of tools
- Single Brewfile for both platforms

**Homebrew location on Linux:** `/home/linuxbrew/.linuxbrew/`

**Adding to PATH:**
The bootstrap process reminds you to add Homebrew to your PATH. If needed:

```bash
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Font Installation

JetBrains Mono is installed via Homebrew on both platforms. On Linux, Homebrew installs fonts to:
- `~/.linuxbrew/share/fonts/`

After installing fonts, you may need to:
```bash
fc-cache -f -v  # Refresh font cache
```

Then configure your terminal emulator to use "JetBrains Mono".

### Platform Detection

The dotfiles automatically detect your OS via `$DOTFILES_OS` variable:
- Set in `zsh/zsh.d/05-os-detection.zsh`
- Used by platform-specific aliases (`pubkey`, `afk`, `flushdns`)
- Available for use in local configurations

### Differences from macOS

| Feature | macOS | Linux |
|---------|-------|-------|
| Clipboard | `pbcopy`/`pbpaste` | `xclip` or `wl-copy` |
| Lock screen | `pmset displaysleepnow` | `loginctl lock-session` |
| DNS flush | `dscacheutil` | `resolvectl flush-caches` |
| System settings | `macos/settings.sh` | Manual (distro-specific) |
| Font location | `~/Library/Fonts/` | `~/.linuxbrew/share/fonts/` |

## Troubleshooting

**Starship prompt not loading:**
```bash
# Check if starship is in PATH
command -v starship

# Reload shell
reload
```

**fzf tab completion not working:**
```bash
# Check if fzf-tab is installed
ls ~/.oh-my-zsh/custom/plugins/fzf-tab

# Reinstall if missing
git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
reload
```

**Zoxide not working:**
```bash
# Check if zoxide is installed
command -v zoxide

# Install if missing
brew install zoxide
reload
```

**Changes not taking effect:**
```bash
# Reapply symlinks
make restow

# Reload shell
reload
```
