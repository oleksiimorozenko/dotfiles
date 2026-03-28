# Suppress the login message
# echo '' > $HOME/.hushlogin

# ==============================================================================
# Miscellaneous Settings
# ==============================================================================
# Zsh autosuggestions
if [[ "$DOTFILES_OS" == "macos" ]] && command -v brew &>/dev/null; then
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ "$DOTFILES_OS" == "linux" ]]; then
    [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
