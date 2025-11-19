# ==============================================================================
# fzf - Fuzzy Finder Configuration
# ==============================================================================
# fzf provides fuzzy finding for files, command history, and more
# ==============================================================================

# Only configure if fzf is installed
if command -v fzf &> /dev/null; then

# ------------------------------------------------------------------------------
# Core fzf Configuration
# ------------------------------------------------------------------------------

# Use fd instead of find for file searching (faster, respects .gitignore)
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'

# ------------------------------------------------------------------------------
# Preview Commands
# ------------------------------------------------------------------------------

# Preview files with bat (syntax highlighting)
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window right:60%
"

# Preview directories with tree
export FZF_ALT_C_OPTS="
  --preview 'tree -C {} | head -200'
  --preview-window right:60%
"

# ------------------------------------------------------------------------------
# UI Configuration - Catppuccin Mocha Theme
# ------------------------------------------------------------------------------

export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --cycle
  --bind 'ctrl-t:toggle'
  --bind 'ctrl-h:toggle-preview'
  --bind 'ctrl-u:preview-page-up'
  --bind 'ctrl-d:preview-page-down'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# ------------------------------------------------------------------------------
# Custom fd Functions for fzf
# ------------------------------------------------------------------------------

# Override default file path completion to use fd
_fzf_compgen_path() {
  fd --hidden --no-ignore-vcs --exclude .git . "$1"
}

# Override default directory completion to use fd
_fzf_compgen_dir() {
  fd --type=d --hidden --no-ignore-vcs --exclude .git . "$1"
}

# ------------------------------------------------------------------------------
# Initialize fzf
# ------------------------------------------------------------------------------

# Source fzf key bindings and completion
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
elif [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
# Ctrl+T - Paste selected files/directories
# Ctrl+R - Paste selected command from history
# Alt+C  - cd into selected directory
# Ctrl+H - Toggle preview window
# Ctrl+U/D - Scroll preview up/down

fi  # End of fzf installed check
