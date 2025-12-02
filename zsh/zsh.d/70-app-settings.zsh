# ==============================================================================
# Application settings
# ==============================================================================

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# ==============================================================================
# tmux - Session Management (Shell Scripts)
# ==============================================================================
# Session scripts are in ~/.config/tmux/bin/ (added to PATH)
if command -v tmux-init &> /dev/null; then
  alias tsi='tmux-init'
  alias tsi-fresh='tmux-init-fresh'
  alias tsi-attach='tmux attach -t init'
fi
