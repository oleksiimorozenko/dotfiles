# ==============================================================================
# Tailscale helpers
# ==============================================================================
# There is no Tailscale GUI on Linux, and even on macOS toggling an exit node
# through the menu bar is slower than typing. These wrap the CLI.
#
#   tsexit              show the current exit node
#   tsexit list         list nodes offering to be an exit node
#   tsexit <node>       route through <node>
#   tsexit off          stop using an exit node
# ==============================================================================

# The CLI lives in different places per platform, and the macOS app bundle is
# not on PATH by default.
_ts_bin() {
  if command -v tailscale &> /dev/null; then
    command -v tailscale
  elif [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
    echo /Applications/Tailscale.app/Contents/MacOS/Tailscale
  else
    return 1
  fi
}

# Linux needs root to change prefs; the macOS app does not.
_ts_sudo() {
  [[ "$DOTFILES_OS" == "linux" ]] && echo sudo
}

tsexit() {
  local ts; ts=$(_ts_bin) || { echo "tailscale CLI not found" >&2; return 1; }
  local sudo_cmd; sudo_cmd=$(_ts_sudo)

  case "$1" in
    ""|status)
      local current
      current=$("$ts" debug prefs 2>/dev/null | grep -o '"ExitNodeID": *"[^"]*"' | cut -d'"' -f4)
      if [[ -n "$current" ]]; then
        echo "exit node: $current"
      else
        echo "exit node: none (direct)"
      fi
      ;;
    list|ls)
      "$ts" exit-node list 2>/dev/null || \
        echo "no exit nodes offered, or this Tailscale build lacks 'exit-node list'"
      ;;
    off|none|clear)
      ${sudo_cmd:+$sudo_cmd} "$ts" set --exit-node=
      echo "exit node cleared"
      ;;
    *)
      # --exit-node-allow-lan-access matters: without it, routing through an
      # exit node also blackholes the local LAN, which is how you lose SSH to
      # everything on your own subnet.
      ${sudo_cmd:+$sudo_cmd} "$ts" set --exit-node="$1" --exit-node-allow-lan-access=true \
        && echo "exit node: $1 (LAN access preserved)"
      ;;
  esac
}

# Quick aliases for the common case
alias tsoff='tsexit off'
alias tsls='tsexit list'
