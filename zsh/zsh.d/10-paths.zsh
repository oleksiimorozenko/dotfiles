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

# Shared (group-writable) Homebrew: zsh's compaudit treats brew's own function
# dirs as "insecure" and strips them from fpath, so compinit cannot find
# compdump ("compdump: function definition file not found"). The group-write is
# intentional on a shared-brew host (one operator, two accounts), so skip the
# compfix check, but ONLY when the prefix really is group/other-writable, which
# keeps the security check intact on single-user boxes (e.g. the Mac).
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/functions" ]]; then
  zmodload -F zsh/stat b:zstat 2>/dev/null
  typeset -a _hb_mode
  zstat -A _hb_mode +mode "$HOMEBREW_PREFIX/share/zsh/functions" 2>/dev/null
  (( ${_hb_mode[1]:-0} & 0022 )) && export ZSH_DISABLE_COMPFIX=true
  unset _hb_mode
fi

# LM Studio CLI (if exists)
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# Java (macOS only)
# if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /usr/libexec/java_home ]]; then
#   export JAVA_HOME=$(/usr/libexec/java_home)
# fi

export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$HOME/.claude/local:$PATH"
