# ==============================================================================
# ~/.zshenv - ZSH Environment Bootstrap
# ==============================================================================
# This file is sourced on all shell invocations
# It sets up XDG Base Directory and points to the real config

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Set ZDOTDIR to XDG-compliant location
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
