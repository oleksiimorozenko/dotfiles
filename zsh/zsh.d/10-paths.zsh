# ==============================================================================
# PATH configuration
# ==============================================================================

# Manpath
export MANPATH="/usr/local/man:$MANPATH"

# Core paths
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Tmux session scripts
export PATH="$XDG_CONFIG_HOME/tmux/bin:$PATH"

# Homebrew
# Sets up PATH, FPATH (for completions), MANPATH, and INFOPATH, and exports
# HOMEBREW_PREFIX which later modules use instead of hardcoding a path.
# The prefix differs by platform: /opt/homebrew on Apple Silicon,
# /home/linuxbrew/.linuxbrew on Linux.
if [[ "$DOTFILES_OS" == "macos" && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ "$DOTFILES_OS" == "linux" && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# LM Studio CLI (if exists)
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# Java (macOS only)
# if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /usr/libexec/java_home ]]; then
#   export JAVA_HOME=$(/usr/libexec/java_home)
# fi

export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$HOME/.claude/local:$PATH"
