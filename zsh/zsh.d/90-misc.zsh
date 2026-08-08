# Suppress the login message
# echo '' > $HOME/.hushlogin

# ==============================================================================
# Miscellaneous Settings
# ==============================================================================
# Zsh autosuggestions. Prefer the brew copy ($HOMEBREW_PREFIX, set in
# 10-paths.zsh) since both macOS and Linux use brew here; the old Linux branch
# only checked /usr/share (apt) and so loaded nothing on the linuxbrew VM.
if [[ -n "$HOMEBREW_PREFIX" && -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
