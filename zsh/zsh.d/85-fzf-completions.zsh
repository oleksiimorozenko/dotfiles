# ==============================================================================
# fzf-tab - Custom Completion Previews
# ==============================================================================
# Configure fzf-tab to show previews for various commands
# ==============================================================================

# Only configure if fzf is installed
if command -v fzf &> /dev/null; then

# ------------------------------------------------------------------------------
# General fzf-tab Configuration
# ------------------------------------------------------------------------------

# Disable default completion menu (let fzf-tab handle it)
zstyle ':completion:*' menu no

# Switch between completion groups with '[' and ']'
zstyle ':fzf-tab:*' switch-group '[' ']'

# Use reverse-list layout (matches fzf config)
zstyle ':fzf-tab:*' fzf-flags --layout=reverse-list

# Show hidden files in completions
zstyle ':completion:*' special-dirs true

# Hide unwanted patterns from completions
zstyle ':completion:*' ignored-patterns '.|..|.DS_Store|**/.|**/..|**/.DS_Store|**/.git'

# Hide parent directories from menu
zstyle ':completion:*' ignore-parents 'parent pwd directory'

# ------------------------------------------------------------------------------
# Command-Specific Preview Configurations
# ------------------------------------------------------------------------------

# File operations: ls, cat, cd, rm, cp, mv, etc.
# Use inline command instead of function to avoid scope issues
zstyle ':fzf-tab:complete:(ls|eza|bat|cat|cd|rm|cp|mv|ln|nano|code|vim|nvim|open|tail|head|less|more):*' \
  fzf-preview '[[ -d $realpath ]] && { tree -C -L 2 $realpath 2>/dev/null || ls -la $realpath } || { bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath }'

# Git operations
zstyle ':fzf-tab:complete:git-(diff|log|show):*' \
  fzf-preview 'git diff --color=always $word'

zstyle ':fzf-tab:complete:git-checkout:*' \
  fzf-preview 'git log --oneline --graph --color=always $word | head -50'

# Man pages
zstyle ':fzf-tab:complete:(\\|*/|)man:*' \
  fzf-preview 'man $word | col -bx | bat --color=always --language=man --style=plain'

# Kill/killall: show process info
zstyle ':fzf-tab:complete:(kill|killall):*' \
  fzf-preview 'ps aux | grep $word | grep -v grep'

# Environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
  fzf-preview 'echo ${(P)word}'

# Homebrew packages
zstyle ':fzf-tab:complete:brew-(install|uninstall|info):*' \
  fzf-preview 'brew info $word'

# Docker containers
zstyle ':fzf-tab:complete:docker-(start|stop|rm|exec):*' \
  fzf-preview 'docker inspect $word | jq -r ".[].Config.Image"'

# Kubectl resources
zstyle ':fzf-tab:complete:kubectl-*:*' \
  fzf-preview 'kubectl describe $word 2>/dev/null'

# SSH hosts (from ~/.ssh/config)
zstyle ':fzf-tab:complete:ssh:*' \
  fzf-preview 'echo "Host: $word"'

# ------------------------------------------------------------------------------
# Make Completions with Preview
# ------------------------------------------------------------------------------

# Show what the make target will do
zstyle ':fzf-tab:complete:make:*' \
  fzf-preview 'make -n $word 2>/dev/null || echo "Target: $word"'

# ------------------------------------------------------------------------------
# Custom zoxide Completion (z command)
# ------------------------------------------------------------------------------

# Show directory preview for z command (zoxide provides its own completion)
if command -v zoxide &> /dev/null; then
  zstyle ':fzf-tab:complete:z:*' \
    fzf-preview 'tree -C -L 2 $word 2>/dev/null || ls -la $word'

  zstyle ':fzf-tab:complete:zi:*' \
    fzf-preview 'tree -C -L 2 $word 2>/dev/null || ls -la $word'
fi

# ==============================================================================
# Usage:
# ==============================================================================
# After this configuration, tab completion will show fzf with previews:
#
#   ls <TAB>        # Shows files with bat preview
#   cd <TAB>        # Shows directories with tree preview
#   man <TAB>       # Shows man page preview
#   kill <TAB>      # Shows process info
#   z <TAB>         # Shows directory preview for zoxide
#
# Press '[' and ']' to switch between completion groups
# Press Ctrl+H to toggle preview window (from fzf config)
# ==============================================================================

fi  # End of fzf installed check
