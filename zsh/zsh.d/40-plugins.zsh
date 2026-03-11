# ==============================================================================
# Oh-My-Zsh plugins
# ==============================================================================

# Plugins
# Note: fzf-tab must be loaded first for proper tab completion integration
plugins=(
  aliases
  command-not-found
  gh
  git
  gitignore
  helm
  kubectl
  starship
  terraform
  tmux
)

# fzf-tab: custom plugin, only available if cloned (make bootstrap / Dockerfile)
[[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/fzf-tab" ]] && plugins=(fzf-tab $plugins)

# macOS-only plugins
if [[ "$DOTFILES_OS" == "macos" ]]; then
  plugins+=(brew macos vscode)
fi

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh
