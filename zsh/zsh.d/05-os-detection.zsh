# ==============================================================================
# OS Detection
# ==============================================================================
# Detects the operating system and exports DOTFILES_OS variable for use in
# other modules. This allows platform-specific configurations without
# repeatedly checking $OSTYPE.
#
# Exported Variables:
#   DOTFILES_OS - "macos", "linux", or "unknown"
#
# Usage in other modules:
#   if [[ "$DOTFILES_OS" == "macos" ]]; then
#       # macOS-specific code
#   elif [[ "$DOTFILES_OS" == "linux" ]]; then
#       # Linux-specific code
#   fi
# ==============================================================================

export DOTFILES_OS="unknown"

if [[ "$OSTYPE" == "darwin"* ]]; then
    export DOTFILES_OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export DOTFILES_OS="linux"
fi

# Optional: Export additional platform info
if [[ "$DOTFILES_OS" == "linux" ]]; then
    # Detect Linux distribution (optional, for future use)
    if [[ -f /etc/os-release ]]; then
        export DOTFILES_LINUX_DISTRO=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
fi
