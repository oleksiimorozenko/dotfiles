# ==============================================================================
# Editor Settings
# ==============================================================================

# Set preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  # Use neovim if available, otherwise vim
  if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
  else
    export EDITOR='vim'
    export VISUAL='vim'
  fi
fi
