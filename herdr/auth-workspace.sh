#!/usr/bin/env bash
# Build the "auth" herdr workspace: a repeatable predefined layout.
#
#   +----------------------+----------------------+
#   |  awsom (top-left)    |  ol.sh (top-right)   |
#   +----------------------+----------------------+
#   |  awsgm (bottom, full width)                 |
#   +---------------------------------------------+
#
# herdr 0.8.0 has no declarative workspace-layout config, so this scripts it over
# the socket API: create the workspace, split panes, then type each command into
# the pane's interactive shell with send-text (needed so zsh functions like
# `awsgm` resolve — `pane run` would spawn a bare process without them).
#
# Run it any time: ~/.config/herdr/auth-workspace.sh
# Copy/extend this for more predefined workspaces.
set -euo pipefail
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# First pane_id found anywhere in a herdr JSON result.
_pid() { python3 -c "import json,sys
def f(o):
 if isinstance(o,dict):
  if isinstance(o.get('pane_id'),str): return o['pane_id']
  for v in o.values():
   r=f(v)
   if r: return r
 if isinstance(o,list):
  for v in o:
   r=f(v)
   if r: return r
 return None
print(f(json.load(sys.stdin)) or '')"; }

TL=$(herdr workspace create --label auth --focus | _pid)   # top-left
BOT=$(herdr pane split "$TL" --direction down  --ratio 0.35 | _pid)  # bottom
TR=$(herdr pane split "$TL" --direction right --ratio 0.50 | _pid)   # top-right

sleep 2   # let the interactive shells initialize before typing into them
herdr pane send-text "$TL" $'awsom\n'
if [[ -x "$HOME/ai-workspaces/ol.sh" ]]; then
  herdr pane send-text "$TR" $'~/ai-workspaces/ol.sh\n'
else
  herdr pane send-text "$TR" $'echo "ol.sh not found in ~/ai-workspaces (mbpsa sync pending)"\n'
fi
herdr pane send-text "$BOT" $'awsgm\n'

echo "auth workspace ready (TL=$TL awsom, TR=$TR ol.sh, BOT=$BOT awsgm)"
