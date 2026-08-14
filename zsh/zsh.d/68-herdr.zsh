# ==============================================================================
# herdr config path
# ==============================================================================
# herdr owns ~/.config/herdr as its runtime dir (sockets, logs, session state)
# and rewrites files there, so stowing config.toml as a symlink into it does not
# survive. Instead point herdr at the dotfiles copy via its documented override
# (herdr --help: "Env: HERDR_CONFIG_PATH overrides config file path"). This also
# fixes `herdr --remote`, whose keybindings default to the LOCAL config.
# Note: with `herdr --remote`, keybindings default to the CLIENT machine's
# config (--remote-keybindings local), so this only governs a local attach and
# the CLI. Pass --remote-keybindings server to make this file authoritative.
[[ -f "$HOME/git/oleksiimorozenko/dotfiles/herdr/config.toml" ]] && \
  export HERDR_CONFIG_PATH="$HOME/git/oleksiimorozenko/dotfiles/herdr/config.toml"
