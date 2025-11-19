# ==============================================================================
# Oh-My-Zsh plugins
# ==============================================================================

# Plugins
# Note: fzf-tab must be loaded first for proper tab completion integration
plugins=(
  fzf-tab
  aliases
  brew
  command-not-found
  gh
  git
  gitignore
  helm
  kubectl
  macos
  starship
  terraform
  tmux
  vscode
)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh
