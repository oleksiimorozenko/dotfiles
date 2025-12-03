# ==============================================================================
# Shell Functions
# ==============================================================================

# Navigate and list
cx() { cd "$@" && l; }

# Fuzzy find directory and cd
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && l; }

# Fuzzy find file and copy to clipboard
f() { echo "$(find . -type f -not -path '*/.*' | fzf)" | pbcopy }

# Fuzzy find file and edit
fv() { ${EDITOR:-vim} "$(find . -type f -not -path '*/.*' | fzf)" }

# AWS morning authentication - authenticates to all needed profiles
awsgm() {
    local config_file="$HOME/.config/zsh/local/awsgm.conf"

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        echo ""
        echo "Create $config_file with:"
        echo "  sso_session=your-sso-session-name"
        echo "  profiles=profile1,profile2,profile3"
        echo ""
        echo "Example:"
        echo "  sso_session=MyCompanySSO"
        echo "  profiles=dev,staging,production"
        return 1
    fi

    # Parse config file
    local session_name=""
    local profiles_str=""

    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        key="${key//[[:space:]]/}"
        value="${value//[[:space:]]/}"

        case "$key" in
            sso_session) session_name="$value" ;;
            profiles) profiles_str="$value" ;;
        esac
    done < "$config_file"

    # Validate configuration
    if [[ -z "$session_name" ]]; then
        echo "Error: 'sso_session' not set in $config_file"
        return 1
    fi

    if [[ -z "$profiles_str" ]]; then
        echo "Error: 'profiles' not set in $config_file"
        return 1
    fi

    # Split profiles by comma
    local profiles=("${(@s/,/)profiles_str}")

    # Original awsgm logic starts here
    echo "Starting morning authentication routine..."

    # Check if SSO session is active, start if needed
    if ! awsom session status --session-name "$session_name" --json | grep -q '"active":true'; then
        echo "SSO session not active, logging in..."
        awsom session login --session-name "$session_name"

        # Wait for session to become active (token may not be immediately available)
        echo "Waiting for session to be ready..."
        local max_attempts=10
        local attempt=1
        while [ $attempt -le $max_attempts ]; do
            if awsom session status --session-name "$session_name" --json | grep -q '"active":true'; then
                echo "Session ready!"
                break
            fi
            if [ $attempt -eq $max_attempts ]; then
                echo "Warning: Session still not active after $max_attempts attempts"
                return 1
            fi
            sleep 1
            ((attempt++))
        done
    else
        echo "SSO session already active"
    fi

    for profile in "${profiles[@]}"; do
        echo "Starting $profile..."
        awsom profile start "$profile"
    done
    echo "Ready!"
}
