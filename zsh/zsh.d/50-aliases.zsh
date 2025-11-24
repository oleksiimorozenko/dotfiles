# ==============================================================================
# Aliases
# ==============================================================================
# Kubernetes
alias kc="kubectx"
alias kns="kubens"

# Modern CLI replacements
alias cat='bat --style=plain --paging=never'    # Standard cat replacement
alias catl='bat'                                # Print line numbers
alias grep='rg'                                 # Fast searching with ripgrep
alias l='eza -al'                               # Quick detailed listing
alias ll='eza --git --icons -l'                 # Detailed listing
alias ls='eza'                                  # Better ls
alias lt='eza --git --icons --level=2 --long --tree'    # Tree view (replaces old 'la=tree')
alias ltree="eza --git --icons --level=2 --tree"
alias v="nvim"
alias ps='procs'                                # Modern ps with colors and tree view
alias pst='procs --tree'                        # Process tree view
alias disk='ncdu --color dark'                  # Interactive disk usage analyzer

# Terraform
alias tfplan='terraform init && terraform fmt -diff && terraform validate && terraform plan'
alias tfv='terraform init && terraform fmt -diff && terraform validate'

# Zsh management
alias reload="source $ZDOTDIR/.zshrc"
alias zshconfig="${EDITOR:-vim} $ZDOTDIR/.zshrc"

# Network tools
# Comented out because of frequent error like Error: No RDAP servers found for domain ....
# alias whois='echo "Using rdap instead"; rdap'

# Platform-specific aliases
if [[ "$DOTFILES_OS" == "macos" ]]; then
    # macOS utilities
    alias pubkey="cat ~/.ssh/id_rsa.pub | pbcopy && echo 'SSH public key copied to clipboard'"
    alias afk='pmset displaysleepnow'  # Lock screen immediately
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
elif [[ "$DOTFILES_OS" == "linux" ]]; then
    # Linux utilities
    # Clipboard: Try xclip first (X11), then wl-copy (Wayland)
    if command -v xclip &> /dev/null; then
        alias pubkey="cat ~/.ssh/id_rsa.pub | xclip -selection clipboard && echo 'SSH public key copied to clipboard'"
    elif command -v wl-copy &> /dev/null; then
        alias pubkey="cat ~/.ssh/id_rsa.pub | wl-copy && echo 'SSH public key copied to clipboard'"
    else
        alias pubkey="echo 'Install xclip (X11) or wl-clipboard (Wayland) for clipboard support'"
    fi

    # Lock screen
    alias afk='loginctl lock-session'

    # DNS cache flush (systemd-resolved)
    if command -v resolvectl &> /dev/null; then
        alias flushdns='sudo resolvectl flush-caches'
    elif command -v systemd-resolve &> /dev/null; then
        alias flushdns='sudo systemd-resolve --flush-caches'
    else
        alias flushdns='echo "DNS caching not detected (no systemd-resolved)"'
    fi
fi
