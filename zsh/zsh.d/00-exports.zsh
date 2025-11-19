# ==============================================================================
# Common environment variables
# ==============================================================================

# Locale
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# GPG TTY
export GPG_TTY=$(tty)

# Set less charset for proper Unicode display
export LESSCHARSET=utf-8
# Define Unicode character ranges for less
export LESSUTFCHARDEF="E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

# Bat configuration directory
export BAT_CONFIG_DIR="$HOME/.config/bat"
