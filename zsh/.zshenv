# ==============================================================================
# XDG-compliant ZSH Environment Configuration
# ==============================================================================
# This file is loaded from ~/.config/zsh/.zshenv
# Additional environment setup can go here

# Ensure XDG directories exist
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"
