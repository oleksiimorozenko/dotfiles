# ==============================================================================
# Shell Completions
# ==============================================================================

# Show hidden files and special directories (., ..) in completions
zstyle ':completion:*' special-dirs true

# Show dotfiles in completion without requiring a leading dot
_comp_options+=(globdots)

# Only run completions if the completion system is loaded
if (( $+functions[compdef] )); then
  # Packer (if installed)
  if command -v packer &> /dev/null; then
    complete -o nospace -C /opt/homebrew/bin/packer packer 2>/dev/null || \
    complete -o nospace -C /usr/local/bin/packer packer 2>/dev/null
  fi

  # UV (if installed)
  if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion zsh)"
  fi

  # UVX (if installed)
  if command -v uvx &> /dev/null; then
    eval "$(uvx --generate-shell-completion zsh)"
  fi
fi
