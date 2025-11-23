.PHONY: install uninstall restow list help clean bootstrap deps prereq-check prereq-install tmux-plugins

# Detect operating system
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
    OS := macos
else ifeq ($(UNAME),Linux)
    OS := linux
else
    OS := unknown
endif

help:
	@echo "Dotfiles Management (Platform: $(OS))"
	@echo ""
	@echo "Setup:"
	@echo "  make prereq-check    - Check if prerequisites are installed"
	@echo "  make prereq-install  - Install prerequisites (git, zsh, curl)"
	@echo "  make bootstrap       - Install Homebrew, Oh-My-Zsh, fzf-tab, and TPM"
	@echo "  make deps            - Install all dependencies via Brewfile"
	@echo "  make tmux-plugins    - Show how to install tmux plugins"
	@echo ""
	@echo "Dotfiles:"
	@echo "  make install    - Install all dotfiles"
	@echo "  make uninstall  - Remove all dotfiles"
	@echo "  make restow     - Re-apply dotfiles (useful after changes)"
	@echo ""
	@echo "Utilities:"
	@echo "  make list       - List available packages"
	@echo "  make clean      - Remove dead symlinks"
	@echo "  make help       - Show this help"

prereq-check:
	@echo "Checking prerequisites for $(OS)..."
	@echo ""
	@# Check git
	@if command -v git &> /dev/null; then \
		echo "✓ git: $$(git --version)"; \
	else \
		echo "✗ git: Not installed"; \
	fi
	@# Check zsh
	@if command -v zsh &> /dev/null; then \
		echo "✓ zsh: $$(zsh --version)"; \
	else \
		echo "✗ zsh: Not installed"; \
	fi
	@# Check curl
	@if command -v curl &> /dev/null; then \
		echo "✓ curl: $$(curl --version | head -n1)"; \
	else \
		echo "✗ curl: Not installed"; \
	fi
	@# Check stow
	@if command -v stow &> /dev/null; then \
		echo "✓ stow: $$(stow --version | head -n1)"; \
	else \
		echo "✗ stow: Not installed (will be installed via Homebrew)"; \
	fi
	@echo ""
ifeq ($(OS),macos)
	@echo "macOS detected - Command Line Tools check:"
	@if xcode-select -p &> /dev/null; then \
		echo "✓ Xcode Command Line Tools installed"; \
	else \
		echo "✗ Xcode Command Line Tools not installed"; \
		echo "  Run: xcode-select --install"; \
	fi
endif

prereq-install:
	@echo "Installing prerequisites for $(OS)..."
	@echo ""
ifeq ($(OS),macos)
	@echo "macOS: Checking Xcode Command Line Tools..."
	@if ! xcode-select -p &> /dev/null; then \
		echo "Installing Xcode Command Line Tools..."; \
		xcode-select --install; \
		echo "Please complete the installation and re-run this command"; \
		exit 1; \
	else \
		echo "✓ Xcode Command Line Tools already installed"; \
	fi
	@echo ""
	@echo "Other prerequisites (git, zsh, curl) are included with macOS"
else ifeq ($(OS),linux)
	@echo "Linux: Installing git, zsh, curl..."
	@# Detect package manager
	@if command -v apt &> /dev/null; then \
		echo "Detected: apt (Ubuntu/Debian)"; \
		sudo apt update; \
		sudo apt install -y git zsh curl; \
	elif command -v dnf &> /dev/null; then \
		echo "Detected: dnf (Fedora/RHEL)"; \
		sudo dnf install -y git zsh curl; \
	elif command -v pacman &> /dev/null; then \
		echo "Detected: pacman (Arch)"; \
		sudo pacman -S --noconfirm git zsh curl; \
	else \
		echo "Error: Unknown package manager"; \
		echo "Please install git, zsh, and curl manually"; \
		exit 1; \
	fi
	@echo "✓ Prerequisites installed"
else
	@echo "Error: Unknown operating system"
	@exit 1
endif
	@echo ""
	@echo "Prerequisites check:"
	@make prereq-check

bootstrap:
	@echo "Bootstrapping environment for $(OS)..."
	@echo ""
	@# Check if Homebrew is installed
	@if ! command -v brew &> /dev/null; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "Homebrew installed"; \
		if [ "$(OS)" = "linux" ]; then \
			echo ""; \
			echo "IMPORTANT: Add Homebrew to your PATH:"; \
			echo "  echo 'eval \"\$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> ~/.profile"; \
			echo "  eval \"\$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""; \
			echo ""; \
			echo "Or the installer may have already added it. Reload your shell."; \
		fi; \
	else \
		echo "✓ Homebrew already installed"; \
	fi
	@echo ""
	@# Check if Oh-My-Zsh is installed
	@if [ ! -d ~/.oh-my-zsh ]; then \
		echo "Installing Oh-My-Zsh..."; \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
		echo "Oh-My-Zsh installed"; \
	else \
		echo "Oh-My-Zsh already installed"; \
	fi
	@echo ""
	@# Check if fzf-tab plugin is installed
	@if [ ! -d ~/.oh-my-zsh/custom/plugins/fzf-tab ]; then \
		echo "Installing fzf-tab plugin..."; \
		git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab; \
		echo "fzf-tab installed"; \
	else \
		echo "fzf-tab already installed"; \
	fi
	@echo ""
	@# Check if TPM (Tmux Plugin Manager) is installed
	@if [ ! -d ~/.tmux/plugins/tpm ]; then \
		echo "Installing TPM (Tmux Plugin Manager)..."; \
		mkdir -p ~/.tmux/plugins; \
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; \
		echo "TPM installed"; \
		echo "Note: After tmux config is set up, press prefix + I to install plugins"; \
	else \
		echo "TPM already installed - syncing to latest version..."; \
		cd ~/.tmux/plugins/tpm && git pull --quiet; \
		echo "✓ TPM updated to latest version"; \
	fi
	@echo ""
	@echo "Bootstrap complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run: make deps"
	@echo "  2. Run: make install"
	@echo "  3. Start tmux and press Ctrl-a + I to install plugins"

deps:
	@echo "Installing dependencies from Brewfile..."
	@brew bundle
	@echo "Dependencies installed!"
#  2>/dev/null || true
install:
	@echo "Installing dotfiles..."
	@# Install $HOME files first (e.g., ~/.zshenv)
	@stow --dir=. --target=$$HOME home
	@# Install everything else to ~/.config via .stowrc
	@stow --ignore=home .
	@echo "Dotfiles installed!"
	@# Rebuild bat cache to register custom themes
	@if command -v bat &> /dev/null; then \
		echo "Rebuilding bat cache..."; \
		bat cache --build &> /dev/null; \
		echo "Bat cache rebuilt"; \
	fi
	@echo ""
	@echo "Next steps:"
	@echo "  1. Start tmux and press Ctrl-a + I to install plugins"
	@echo "  2. Reload shell: exec zsh"
	@echo "  3. Edit local config: vim ~/.config/zsh/local/local.zsh"
#  2>/dev/null || true
uninstall:
	@echo "Removing dotfiles..."
	@stow --delete --dir=. --target=$$HOME home
	@stow --delete --ignore=home .
	@echo "Dotfiles removed"
#  2>/dev/null || true
restow:
	@echo "Re-stowing dotfiles..."
	@stow --restow --dir=. --target=$$HOME home
	@stow --restow --dir=. --ignore=home .
	@echo "Dotfiles re-stowed"
	@# Rebuild bat cache to register custom themes
	@if command -v bat &> /dev/null; then \
		bat cache --build &> /dev/null; \
		echo "Bat cache rebuilt"; \
	fi

list:
	@echo "Available packages:"
	@find . -maxdepth 1 -type d ! -name '.*' ! -name 'home' | sed 's#\./##' | sort

clean:
	@echo "Cleaning up dead symlinks..."
	@find ~/.config -xtype l -delete 2>/dev/null || true
	@echo "Dead symlinks removed"

tmux-plugins:
	@echo "To install tmux plugins:"
	@echo ""
	@echo "  1. Start tmux:  tmux"
	@echo "  2. Install:     Press Ctrl-a + I (capital I)"
	@echo ""
	@echo "Plugins will be installed to ~/.tmux/plugins/"
	@echo ""
	@if [ ! -d ~/.tmux/plugins/tpm ]; then \
		echo "Note: TPM not installed. Run 'make bootstrap' first."; \
	fi
