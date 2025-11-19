# Tmux Keybinding Cheatsheet

**Prefix Key:** `Ctrl-a` (instead of default `Ctrl-b`)

All commands below require pressing the prefix first unless noted otherwise.

## Quick Reference

| Action | Keybinding | Notes |
|--------|------------|-------|
| Reload config | `r` | Shows "Config reloaded!" |
| Enter command mode | `:` | Type tmux commands |
| List all keybindings | `?` | Scrollable list |
| Detach from session | `d` | Session keeps running |

---

## Sessions

| Action | Keybinding | Notes |
|--------|------------|-------|
| New session | `:new -s name` | Creates named session |
| List sessions | `s` | Switch between sessions |
| Rename session | `$` | |
| Detach | `d` | Session keeps running |
| Kill session | `:kill-session` | |

**Outside tmux:**
```bash
tmux                    # Start new session
tmux new -s name        # Start named session
tmux ls                 # List sessions
tmux attach -t name     # Attach to session
tmux kill-session -t name  # Kill specific session
tmux kill-server        # Kill all sessions
```

**OMZ tmux plugin aliases:**
```bash
ta name        # tmux attach -t name
tad name       # tmux attach -d -t name
ts name        # tmux new-session -s name
tl             # tmux list-sessions
tkss name      # tmux kill-session -t name
tksv           # tmux kill-server
```

---

## Windows (Tabs)

| Action | Keybinding | Notes |
|--------|------------|-------|
| New window | `c` | |
| Close window | `&` | Prompts for confirmation |
| Next window | `n` | |
| Previous window | `p` | |
| Select window 0-9 | `0-9` | Direct jump |
| Rename window | `,` | |
| List windows | `w` | Visual picker |
| Find window | `f` | Search by name |
| Last window | `l` | Toggle between last two |

---

## Panes

### Splitting (via tmux-pain-control)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Split horizontal | `|` | New pane on right |
| Split vertical | `-` | New pane below |
| Split full-width horizontal | `\` | Full terminal width |
| Split full-width vertical | `_` | Full terminal height |

### Navigation (via tmux-pain-control)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Select pane left | `h` or `Ctrl+Alt-Left` | Ctrl+Alt doesn't need prefix |
| Select pane down | `j` or `Ctrl+Alt-Down` | |
| Select pane up | `k` or `Ctrl+Alt-Up` | |
| Select pane right | `l` or `Ctrl+Alt-Right` | |
| Cycle through panes | `o` | |
| Show pane numbers | `q` | Press number to select |

### Resizing (via tmux-pain-control)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Resize left | `H` or `Shift-Left` | Repeatable |
| Resize down | `J` or `Shift-Down` | Repeatable |
| Resize up | `K` or `Shift-Up` | Repeatable |
| Resize right | `L` or `Shift-Right` | Repeatable |

### Management

| Action | Keybinding | Notes |
|--------|------------|-------|
| Close pane | `x` | Prompts for confirmation |
| Zoom/unzoom | `z` | Toggle fullscreen pane |
| Break to window | `!` | Make pane its own window |
| Swap with next | `}` | |
| Swap with previous | `{` | |
| Display pane info | `q` | Shows pane numbers |

---

## Copy Mode (Vim-style)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Enter copy mode | `[` | |
| Exit copy mode | `q` or `Escape` | |
| Start selection | `v` | Like vim visual mode |
| Copy selection | `y` | Copies to system clipboard |
| Copy with Enter | `Enter` | Also copies |
| Paste | `]` | |

### Navigation in Copy Mode

| Action | Keybinding |
|--------|------------|
| Move cursor | `h`, `j`, `k`, `l` |
| Page up | `Ctrl-b` |
| Page down | `Ctrl-f` |
| Half page up | `Ctrl-u` |
| Half page down | `Ctrl-d` |
| Go to top | `g` |
| Go to bottom | `G` |
| Search forward | `/` |
| Search backward | `?` |
| Next search result | `n` |
| Previous result | `N` |

---

## Plugins

### TPM (Tmux Plugin Manager)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Install plugins | `I` | Capital I (Shift-i) |
| Update plugins | `U` | Capital U |
| Uninstall removed | `Alt-u` | Clean up |

### tmux-resurrect

| Action | Keybinding | Notes |
|--------|------------|-------|
| Save session | `Ctrl-s` | Manual save |
| Restore session | `Ctrl-r` | Restore last save |

Sessions are saved to `~/.tmux/resurrect/`

### tmux-pain-control

Provides standard pane keybindings. See Panes section above for details.

| Feature | Description |
|---------|-------------|
| Splitting | `|`, `-`, `\`, `_` for various splits |
| Navigation | `h`, `j`, `k`, `l` vim-style |
| Resizing | `H`, `J`, `K`, `L` and Shift-arrows |
| Swapping | `<`, `>` to swap panes |

### tmux-sessionx (if enabled)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Open session manager | `o` | Fuzzy finder with zoxide |

### tmux-floax (if enabled)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Toggle floating window | `p` | VSCode-style overlay |

### tmux-fzf-url (if enabled)

| Action | Keybinding | Notes |
|--------|------------|-------|
| Find URLs | `u` | Open URLs from scrollback |

### tmux-thumbs

| Action | Keybinding | Notes |
|--------|------------|-------|
| Quick copy | `Space` | Vimium-style hints |

### tmux-fzf

| Action | Keybinding | Notes |
|--------|------------|-------|
| Open fzf menu | `F` | Capital F - access tmux objects via fzf |

---

## Common Tasks

### Create a new project workspace
```bash
tmux new -s project-name
# Then split as needed:
# prefix + | (horizontal split)
# prefix + - (vertical split)
```

### Split into 3 panes (one big, two small)
```
prefix + |    # Split right
prefix + -    # Split bottom-right
prefix + h    # Go back to left pane
```

### Resize panes equally
```bash
prefix + :    # Enter command mode
select-layout even-horizontal   # or even-vertical, tiled
```

### Send same command to all panes
```bash
prefix + :    # Enter command mode
setw synchronize-panes on
# Type commands - goes to all panes
setw synchronize-panes off
```

### Move pane to another window
```bash
prefix + :    # Enter command mode
join-pane -t :2    # Move current pane to window 2
```

---

## Catppuccin Status Modules

Available modules for status bar customization:

| Module | Description |
|--------|-------------|
| `session` | Current session name |
| `directory` | Current directory |
| `date_time` | Date and time |
| `application` | Current application |
| `host` | Hostname |
| `user` | Username |
| `battery` | Battery status |
| `cpu` | CPU usage |
| `load` | System load |
| `weather` | Weather info |

Configure in tmux.conf:
```tmux
set -g status-left "#{E:@catppuccin_status_session}"
set -g status-right "#{E:@catppuccin_status_directory}"
set -ag status-right "#{E:@catppuccin_status_date_time}"
```

---

## Troubleshooting

### Plugins not loading
```bash
# Reinstall plugins
prefix + I

# Or manually:
~/.tmux/plugins/tpm/bin/install_plugins
```

### Reset to defaults
```bash
tmux kill-server
rm -rf ~/.tmux/resurrect/*  # Clear saved sessions
```

### Check tmux version
```bash
tmux -V
```

### View current configuration
```bash
tmux show-options -g        # Global options
tmux show-options -s        # Server options
tmux list-keys              # All keybindings
```
