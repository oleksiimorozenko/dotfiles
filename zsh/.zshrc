# ==============================================================================
# ZSH Configuration
# ==============================================================================
# Main configuration file that loads modular configs from zsh.d/

# Load all configs from zsh.d/ in numerical order
for config in $ZDOTDIR/zsh.d/*.zsh; do
  source $config
done

# Load local overrides if they exist (work-specific, AWS, etc.)
[[ -f $ZDOTDIR/local/.zshrc.local ]] && source $ZDOTDIR/local/.zshrc.local
