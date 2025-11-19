# ==============================================================================
# zoxide - Smart Directory Jumping
# ==============================================================================
# zoxide is a smarter cd command that learns your habits
# Jump to frequently used directories with just a few keystrokes
#
# Usage:
#   z dotfiles    # Jump to ~/git/root/dotfiles
#   z api         # Jump to most frecent directory matching "api"
#   zi            # Interactive directory selection with fzf
#   z -            # Go back to previous directory
#
# ==============================================================================

# Only configure if zoxide is installed
if command -v zoxide &> /dev/null; then
  # Initialize zoxide with ZSH integration
  eval "$(zoxide init zsh)"
fi

# ==============================================================================
# How it works:
# ==============================================================================
# - zoxide tracks directories you visit (via cd, z, etc.)
# - It ranks them by "frecency" (frequency + recency)
# - The 'z' command jumps to the highest ranked match
# - The 'zi' command shows interactive fzf selection
#
# Examples:
#   cd ~/git/root/dotfiles     # Visit a directory (zoxide learns)
#   z dot                      # Later, jump back with partial name
#   zi                         # Browse all tracked directories with fzf
# ==============================================================================
