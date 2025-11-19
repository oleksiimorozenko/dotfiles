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
    if [ -z "$AWS_PROFILE" ]; then
        echo "No AWS_PROFILE set"
        echo "Tip: Use 'awsp <profile>' to set a profile"
    else
        echo "Current Profile: $AWS_PROFILE"
        aws sts get-caller-identity 2>/dev/null || echo "Error: Unable to get AWS identity. Try: aws sso login --profile $AWS_PROFILE"
    fi
}

# Quick AWS SSO login
awslogin() {
    local profile="${1:-$AWS_PROFILE}"
    if [ -z "$profile" ]; then
        echo "Usage: awslogin <profile-name>"
        echo "Or set AWS_PROFILE first: awsp staging"
    else
        echo "Logging into AWS SSO for profile: $profile"
        aws sso login --profile "$profile"
    fi
}
