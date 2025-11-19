# Linux-Specific Configuration Package

This package contains Linux-specific configuration files that are not applicable to macOS.

## Current Status

**Minimal/Placeholder** - This package currently contains placeholder files to preserve directory structure for future use.

## Directory Structure

```
linux/
├── .stow-local-ignore    # Patterns to ignore when stowing
├── README.md             # This file
├── .profile              # Shell profile (placeholder)
├── systemd/user/         # User systemd services (future use)
│   └── .gitkeep
└── config/               # Linux-specific configs (future use)
    └── .gitkeep
```

## Future Use Cases

### systemd/user/
User-level systemd services for:
- SSH agent auto-start
- Custom environment setup
- Background services

Example:
```ini
# systemd/user/ssh-agent.service
[Unit]
Description=SSH Agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
```

### config/
Linux-specific application configs:
- `.xinitrc` - X11 initialization
- `.xprofile` - X session profile
- Desktop environment configs
- Linux-only tool configurations

## Installation

The `linux/` package is automatically stowed on Linux systems:

```bash
make install  # Automatically includes linux/ on Linux
```

Or manually:
```bash
stow linux
```

## Adding New Configs

1. Add files to appropriate subdirectory
2. Update `.stow-local-ignore` if file shouldn't be symlinked
3. Document the purpose in this README
4. Test on Linux system

## Notes

- This package is only relevant on Linux systems
- Most configurations are cross-platform (in `zsh/`, `starship/`, etc.)
- Only add Linux-specific configs here
- Keep placeholders minimal to preserve structure
