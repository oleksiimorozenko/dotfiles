# ==============================================================================
# PATH configuration
# ==============================================================================

# Manpath
export MANPATH="/usr/local/man:$MANPATH"

# Core paths
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Homebrew (macOS only)
# Sets up PATH, FPATH (for completions), MANPATH, and INFOPATH
if [[ "$OSTYPE" == "darwin"* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# LM Studio CLI (if exists)
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# Java (macOS only)
# if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /usr/libexec/java_home ]]; then
#   export JAVA_HOME=$(/usr/libexec/java_home)
# fi

export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$HOME/.claude/local:$PATH"
