# AWS Profile Helper Functions
# Source this file in your .zshrc: source ~/.config/zsh/aws-helpers.zsh

# Quick AWS profile switcher
awsp() {
    if [ -z "$1" ]; then
        echo "Current AWS Profile: ${AWS_PROFILE:-<not set>}"
        echo ""
        echo "Available profiles:"
        grep '^\[profile ' ~/.aws/config | sed 's/\[profile /  - /' | sed 's/\]//'
        echo ""
        echo "Usage: awsp <profile-name>"
        echo "Example: awsp staging"
    else
        export AWS_PROFILE="$1"
        echo "AWS Profile set to: $AWS_PROFILE"
    fi
}

# Show current AWS identity
awswho() {
    if [ -n "$AWS_PROFILE" ]; then
        echo "Profile: $AWS_PROFILE (from AWS_PROFILE)"
    elif grep -q '^\[default\]' ~/.aws/config 2>/dev/null; then
        echo "Profile: default (from config)"
    else
        echo "No AWS_PROFILE set, no [default] in config"
        echo "Tip: Use 'awsp <profile>' to set a profile"
        return 1
    fi
    aws sts get-caller-identity 2>/dev/null || echo "Error: credentials invalid or expired"
}

# Quick AWS SSO login (uses awsom)
awslogin() {
    local profile="${1:-$AWS_PROFILE}"
    if [ -z "$profile" ]; then
        echo "Usage: awslogin <profile-name>"
        echo "Or set AWS_PROFILE first: awsp staging"
        return 1
    fi
    awsom profile start "$profile"
}

# Morning authentication routine
# Add this to your ~/.config/zsh/local/local.zsh with your actual profile names:
#
# awsgm() {
#     echo "Starting morning authentication routine..."
#     local profiles=(dev staging production)  # Customize with your SSO profiles
#
#     for profile in "${profiles[@]}"; do
#         echo "Starting $profile..."
#         awsom profile start "$profile"
#     done
#     echo "Ready!"
# }
