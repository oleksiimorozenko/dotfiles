# ==============================================================================
# Azure Helper Functions
# ==============================================================================
# Verbosity: -v/--verbose (or AZURE_VERBOSE=1) shows progress detail; -d/--debug (or AZURE_DEBUG=1) also shows raw API payloads

# AZ Get Subscription — print current default subscription name (reads local JSON, no API call)
azgs() {
    local profile="${AZURE_CONFIG_DIR:-$HOME/.azure}/azureProfile.json"
    if [[ ! -f "$profile" ]]; then
        echo "(no azure session)" >&2
        return 1
    fi
    jq -r '.subscriptions[] | select(.isDefault==true) | .name' "$profile" 2>/dev/null
}

# AZ Set Subscription — switch active subscription by name or ID
alias azss="az account set --subscription"

_az_debug=0
_az_verbose=0

_az_dbg() {
    [[ "$_az_debug" -eq 1 ]] && echo "  [debug] $*"
}

_az_info() {
    [[ "$_az_verbose" -eq 1 ]] && echo "$*"
}

# Wrapper: suppress stderr unless debug mode is on
_az_run() {
    if [[ "$_az_debug" -eq 1 ]]; then
        "$@"
    else
        "$@" 2>/dev/null
    fi
}

# Parse -d/--debug and -v/--verbose from args, return remaining args
# --debug implies --verbose
_az_parse_debug() {
    _az_debug=0
    _az_verbose=0
    _az_force=0
    [[ "$AZURE_DEBUG" == "1" ]]   && _az_debug=1 && _az_verbose=1
    [[ "$AZURE_VERBOSE" == "1" ]] && _az_verbose=1
    local args=()
    for arg in "$@"; do
        case "$arg" in
            -d|--debug)   _az_debug=1; _az_verbose=1 ;;
            -v|--verbose) _az_verbose=1 ;;
            -f|--force)   _az_force=1 ;;
            *) args+=("$arg") ;;
        esac
    done
    _az_remaining_args=("${args[@]}")
}

# Azure PIM — activate PIM RBAC roles for the day
# Usage: azpim [-d|-v|-f] [init | aks-token [context] | [role-filter...]]
azpim() {
    _az_parse_debug "$@"
    set -- "${_az_remaining_args[@]}"
    case "${1:-}" in
        init)      shift; _azpim_init "$@" ;;
        aks-token) shift; _azpim_aks_token "$@" ;;
        *)         _azpim_activate "$@" ;;
    esac
}

# Interactive config generator
# Usage: azpim init [-f]  — use -f to overwrite an existing config
_azpim_init() {
    local config_file="$HOME/.config/local/azpim.yaml"
    local config_dir
    config_dir=$(dirname "$config_file")

    if [[ -f "$config_file" ]] && [[ "$_az_force" -eq 0 ]]; then
        echo "Config already exists: $config_file"
        echo "Use 'azpim -f init' to overwrite."
        return 1
    fi

    echo "azpim init — creating $config_file"
    echo ""

    # Tenant
    printf "Tenant ID: "
    read -r tenant_id
    [[ -z "$tenant_id" ]] && { echo "Error: tenant ID is required"; return 1; }

    # Reason
    printf "Justification reason [Cloud operations]: "
    read -r reason
    reason="${reason:-Cloud operations}"

    # Duration
    printf "Duration (ISO 8601) [PT8H]: "
    read -r duration
    duration="${duration:-PT8H}"

    # Subscriptions
    local subscriptions_yaml=""
    local first_sub=1
    echo ""
    echo "Add subscriptions (leave name blank to finish):"

    while true; do
        echo ""
        printf "  Subscription name: "
        read -r sub_name
        [[ -z "$sub_name" ]] && break

        printf "  Subscription ID: "
        read -r sub_id
        [[ -z "$sub_id" ]] && { echo "  Error: subscription ID is required"; continue; }

        local default_flag="false"
        if [[ $first_sub -eq 1 ]]; then
            printf "  Set as default subscription? [Y/n]: "
            read -r ans
            [[ "${ans:-Y}" =~ ^[Yy] ]] && default_flag="true"
        else
            printf "  Set as default subscription? [y/N]: "
            read -r ans
            [[ "$ans" =~ ^[Yy] ]] && default_flag="true"
        fi

        # Roles
        local roles_yaml=""
        echo "  Roles (leave blank to finish):"
        while true; do
            printf "    Role name: "
            read -r role_name
            [[ -z "$role_name" ]] && break
            roles_yaml+="      - ${role_name}"$'\n'
        done
        [[ -z "$roles_yaml" ]] && { echo "  Error: at least one role is required"; continue; }

        subscriptions_yaml+="  - name: ${sub_name}"$'\n'
        subscriptions_yaml+="    id: \"${sub_id}\""$'\n'
        [[ "$default_flag" == "true" ]] && subscriptions_yaml+="    default: true"$'\n'
        subscriptions_yaml+="    roles:"$'\n'
        subscriptions_yaml+="$roles_yaml"

        first_sub=0
    done

    if [[ -z "$subscriptions_yaml" ]]; then
        echo ""
        echo "Error: at least one subscription is required"
        return 1
    fi

    # Preview
    local config_content
    config_content="tenant_id: \"${tenant_id}\"
reason: \"${reason}\"
duration: \"${duration}\"

subscriptions:
${subscriptions_yaml}"

    echo ""
    echo "--- Preview ---"
    echo "$config_content"
    echo "---------------"
    printf "Write to %s? [Y/n]: " "$config_file"
    read -r confirm
    [[ "${confirm:-Y}" =~ ^[Nn] ]] && { echo "Aborted."; return 0; }

    mkdir -p "$config_dir"
    echo "$config_content" > "$config_file"
    echo "Written: $config_file"
}

# Internal: activate PIM roles (optionally filtered by role name)
# Usage: _azpim_activate [role-filter...]  — empty = activate all
_azpim_activate() {
    local role_filters=("$@")
    setopt LOCAL_OPTIONS   # option changes (incl. xtrace) are scoped to this function
    { set +x; } 2>/dev/null  # disable xtrace; the 2>/dev/null swallows the xtrace-of-set+x itself
    [[ "$_az_debug"   -eq 1 ]] && echo "(debug mode active — run without -d for quiet output)"
    [[ "$_az_verbose" -eq 1 && "$_az_debug" -eq 0 ]] && echo "(verbose mode active — run without -v for quiet output)"
    [[ "$_az_force"   -eq 1 ]] && echo "(force mode — all roles will be re-activated regardless of current state)"
    local config_file="$HOME/.config/local/azpim.yaml"

    # Validate dependencies
    for tool in az yq jq; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: '$tool' is not installed"
            return 1
        fi
    done

    # Validate config
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        return 1
    fi

    local tenant_id reason duration
    tenant_id=$(yq -r '.tenant_id' "$config_file")
    reason=$(yq -r '.reason' "$config_file")
    duration=$(yq -r '.duration' "$config_file")

    # Validate no more than one default subscription
    local default_count
    default_count=$(yq '[.subscriptions[] | select(.default == true)] | length' "$config_file")
    if [[ "$default_count" -gt 1 ]]; then
        echo "Error: Multiple subscriptions marked as default in $config_file"
        return 1
    fi

    # Azure login (opens browser for MFA)
    # stderr (browser URL message) always shown; stdout (JSON accounts list) suppressed unless verbose
    echo "Logging in to Azure tenant $tenant_id..."
    if [[ "$_az_verbose" -eq 1 ]]; then
        if ! AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" --allow-no-subscriptions; then
            echo "Error: Azure login failed"
            return 1
        fi
    else
        if ! AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" --allow-no-subscriptions > /dev/null; then
            echo "Error: Azure login failed"
            return 1
        fi
    fi

    # Get principal ID
    local principal_id
    principal_id=$(_az_run az ad signed-in-user show --query id -o tsv)
    if [[ -z "$principal_id" ]]; then
        echo "Error: Could not determine signed-in user principal ID"
        return 1
    fi
    _az_info "Principal ID: $principal_id"
    _az_info ""

    # Get management API token explicitly scoped to our tenant
    local mgmt_token
    mgmt_token=$(_az_run az account get-access-token --tenant "$tenant_id" --resource "https://management.azure.com" --query accessToken -o tsv)
    if [[ -z "$mgmt_token" ]]; then
        echo "Error: Could not acquire management API token for tenant $tenant_id"
        return 1
    fi

    local arm_base="https://management.azure.com"

    # Resolve default subscription (needed for both early-return and normal paths)
    local default_sub_id default_sub_name
    default_sub_id=$(yq -r '.subscriptions[] | select(.default == true) | .id' "$config_file")
    default_sub_name=$(yq -r '.subscriptions[] | select(.default == true) | .name' "$config_file")

    # Iterate subscriptions and roles
    local sub_count role_count activated=0 skipped=0 failed=0
    sub_count=$(yq -r '.subscriptions | length' "$config_file")

    echo "Activating PIM roles..."

    for (( s=0; s<sub_count; s++ )); do
        local sub_name sub_id
        sub_name=$(yq -r ".subscriptions[$s].name" "$config_file")
        sub_id=$(yq -r ".subscriptions[$s].id" "$config_file")
        role_count=$(yq -r ".subscriptions[$s].roles | length" "$config_file")

        _az_info "--- $sub_name ($sub_id) ---"

        # Fetch eligible assignments for this subscription
        local eligible_assignments eligible_url
        eligible_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?\$filter=asTarget()&api-version=2020-10-01"
        _az_dbg "GET $eligible_url"
        eligible_assignments=$(curl -s -H "Authorization: Bearer $mgmt_token" "$eligible_url")
        _az_dbg "eligible_assignments=$(echo "$eligible_assignments" | jq -c '.')"

        if [[ -z "$eligible_assignments" ]] || ! echo "$eligible_assignments" | jq -e '.' &>/dev/null; then
            echo "  Warning: Invalid response fetching eligible assignments for $sub_name"
            continue
        fi
        if echo "$eligible_assignments" | jq -e '.error' &>/dev/null; then
            echo "  Warning: Could not fetch eligible assignments for $sub_name"
            echo "  $(echo "$eligible_assignments" | jq -r '.error.message // empty')"
            continue
        fi

        for (( r=0; r<role_count; r++ )); do
            local role_name role_def_id
            role_name=$(yq -r ".subscriptions[$s].roles[$r]" "$config_file")

            # If role filters provided and this role doesn't match, skip silently
            if [[ ${#role_filters[@]} -gt 0 ]]; then
                local matched=0
                for f in "${role_filters[@]}"; do
                    [[ "$role_name" == "$f" ]] && matched=1 && break
                done
                [[ $matched -eq 0 ]] && continue
            fi

            _az_info "  Role: $role_name"

            # Look up role definition ID from eligible assignments
            role_def_id=$(echo "$eligible_assignments" | jq -r \
                --arg name "$role_name" \
                '[.value[] | select(.properties.expandedProperties.roleDefinition.displayName == $name)] | first | .properties.expandedProperties.roleDefinition.id // empty')
            _az_dbg "role_def_id=$role_def_id"

            if [[ -z "$role_def_id" ]]; then
                echo "  [FAIL] $sub_name  $role_name"
                echo "         No eligible assignment found (check role name matches exactly in Azure)"
                failed=$((failed + 1))
                continue
            fi

            # Pre-check: skip entirely if role is already active
            # Avoids deactivating an active role and then failing to reactivate it
            local precheck_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleInstances?\$filter=asTarget()&api-version=2020-10-01"
            local already_active_count
            already_active_count=$(curl -s -H "Authorization: Bearer $mgmt_token" "$precheck_url" | jq -r \
                --arg rd "$role_def_id" --arg pid "$principal_id" \
                '[.value[] | select(.properties.roleDefinitionId == $rd and .properties.principalId == $pid)] | length')
            _az_dbg "already_active_count=${already_active_count:-?}"
            if [[ "${already_active_count:-0}" -gt 0 ]]; then
                if [[ "$_az_force" -eq 0 ]]; then
                    echo "  [SKIP]  $sub_name  $role_name  (already active — use -f to force)"
                    skipped=$((skipped + 1))
                    continue
                fi
                _az_info "  [FORCE] $sub_name  $role_name  (deactivating active role)"
            fi

            # Deactivate first to ensure a fresh activation window
            _az_info "    Deactivating (if active)..."
            local deactivate_guid deactivate_body deactivate_url
            deactivate_guid=$(uuidgen | tr '[:upper:]' '[:lower:]')
            deactivate_body=$(jq -n \
                --arg pid "$principal_id" \
                --arg rdid "$role_def_id" \
                --arg reason "$reason" \
                '{
                    "Properties": {
                        "PrincipalId": $pid,
                        "RoleDefinitionId": $rdid,
                        "RequestType": "SelfDeactivate",
                        "Justification": $reason
                    }
                }')

            deactivate_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$deactivate_guid?api-version=2020-10-01"
            _az_dbg "PUT $deactivate_url"
            _az_dbg "body=$deactivate_body"

            local deactivate_resp
            deactivate_resp=$(curl -s -X PUT \
                -H "Authorization: Bearer $mgmt_token" \
                -H "Content-Type: application/json" \
                -d "$deactivate_body" "$deactivate_url")
            _az_dbg "deactivate_resp=$(echo "$deactivate_resp" | jq -c '.')"

            local deactivate_error_code
            deactivate_error_code=$(echo "$deactivate_resp" | jq -r '.error.code // empty')

            if [[ "$deactivate_error_code" == "RoleAssignmentDoesNotExist" ]]; then
                _az_info "    Not active (skipping deactivation)"
            elif [[ -n "$deactivate_error_code" ]]; then
                _az_info "    Warning: Deactivation error ($deactivate_error_code) — proceeding with activation"
                _az_dbg "$(echo "$deactivate_resp" | jq -r '.error.message // empty')"
            else
                # Wait for deactivation to complete before activating
                _az_info "    Waiting for deactivation..."
                local wait_attempt=0
                local active_check_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleInstances?\$filter=asTarget()&api-version=2020-10-01"
                while [[ $wait_attempt -lt 15 ]]; do
                    sleep 2
                    local active_check
                    active_check=$(curl -s -H "Authorization: Bearer $mgmt_token" "$active_check_url")
                    local still_active
                    still_active=$(echo "$active_check" | jq -r \
                        --arg rd "$role_def_id" \
                        --arg pid "$principal_id" \
                        '[.value[] | select(.properties.roleDefinitionId == $rd and .properties.principalId == $pid)] | length')
                    _az_dbg "still_active=$still_active (attempt $wait_attempt)"
                    if [[ "$still_active" == "0" ]]; then
                        _az_info "    Deactivated"
                        break
                    fi
                    wait_attempt=$((wait_attempt + 1))
                done
                if [[ $wait_attempt -ge 15 ]]; then
                    _az_info "    Warning: Deactivation timed out after 30s — proceeding anyway"
                fi
            fi

            # Activate fresh
            local activate_guid activate_body activate_url
            activate_guid=$(uuidgen | tr '[:upper:]' '[:lower:]')
            activate_body=$(jq -n \
                --arg pid "$principal_id" \
                --arg rdid "$role_def_id" \
                --arg reason "$reason" \
                --arg duration "$duration" \
                '{
                    "Properties": {
                        "PrincipalId": $pid,
                        "RoleDefinitionId": $rdid,
                        "RequestType": "SelfActivate",
                        "Justification": $reason,
                        "ScheduleInfo": {
                            "StartDateTime": null,
                            "Expiration": {
                                "Duration": $duration,
                                "Type": "AfterDuration"
                            }
                        }
                    }
                }')

            activate_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$activate_guid?api-version=2020-10-01"
            _az_dbg "PUT $activate_url"
            _az_dbg "body=$activate_body"

            local activate_resp
            activate_resp=$(curl -s -X PUT \
                -H "Authorization: Bearer $mgmt_token" \
                -H "Content-Type: application/json" \
                -d "$activate_body" "$activate_url")
            _az_dbg "activate_resp=$(echo "$activate_resp" | jq -c '.')"

            local activate_error_code
            activate_error_code=$(echo "$activate_resp" | jq -r '.error.code // empty')
            if [[ -z "$activate_error_code" ]]; then
                echo "  [OK]   $sub_name  $role_name  $duration"
                activated=$((activated + 1))
            elif [[ "$activate_error_code" == "RoleAssignmentExists" ]]; then
                # Race: deactivation submitted but not yet propagated when we activated
                echo "  [SKIP]  $sub_name  $role_name  (role still active, will expire on schedule)"
                skipped=$((skipped + 1))
            else
                echo "  [FAIL] $sub_name  $role_name"
                echo "         $(echo "$activate_resp" | jq -r '.error.message // "Unknown error"')"
                failed=$((failed + 1))
            fi
        done
        _az_info ""
    done

    echo ""

    # Fast path: all roles already active — no need to poll ARM, just sync CLI context
    if [[ "$activated" -eq 0 && "$failed" -eq 0 && "$skipped" -gt 0 ]]; then
        echo "All $skipped PIM role(s) already active. Use 'azpim -f' to force re-activation."
        echo ""
        echo "  Syncing CLI context..."
        # 2>&1 >/dev/null pipes stderr through grep (keeping WARNING: lines) while stdout goes to /dev/null
        AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" 2>&1 >/dev/null | grep "^WARNING:" || true
        if [[ -n "$default_sub_id" ]]; then
            if az account set --subscription "$default_sub_id" 2>/dev/null; then
                echo "  Default subscription: $default_sub_name"
            else
                echo "  Warning: Could not set default subscription"
                echo "  Run: az account set --subscription $default_sub_id  # $default_sub_name"
            fi
        fi
        return 0
    fi

    if [[ "$skipped" -gt 0 ]]; then
        echo "Done: $activated activated, $skipped skipped (already active), $failed failed"
    else
        echo "Done: $activated activated, $failed failed"
    fi

    # Refresh management token — PIM may have changed role assignments since login
    # The original token was issued before activation; a fresh one picks up current permissions
    local fresh_token
    fresh_token=$(_az_run az account get-access-token --tenant "$tenant_id" --resource "https://management.azure.com" --query accessToken -o tsv)
    [[ -n "$fresh_token" ]] && mgmt_token="$fresh_token"

    # Wait for PIM propagation — poll ARM REST directly (safe: does NOT touch CLI account state)
    # Calling `az account list --refresh` in a loop while ARM returns empty clears the CLI session.
    echo ""
    echo -n "Waiting for PIM propagation"
    local refresh_attempt=0
    local sub_found=0
    local poll_url
    if [[ -n "$default_sub_id" ]]; then
        # Check the specific subscription we care about
        poll_url="${arm_base}/subscriptions/${default_sub_id}?api-version=2022-12-01"
    else
        # Fall back to listing all subscriptions
        poll_url="${arm_base}/subscriptions?api-version=2022-12-01"
    fi

    while [[ $refresh_attempt -lt 24 ]]; do
        sleep 5
        printf "."
        local poll_resp
        poll_resp=$(curl -s -H "Authorization: Bearer $mgmt_token" "$poll_url")
        _az_dbg " poll=$(echo "$poll_resp" | jq -c '.subscriptionId // (.value[0].subscriptionId // .error.code // "empty")')"
        if echo "$poll_resp" | jq -e '.subscriptionId // .value[0].subscriptionId' &>/dev/null; then
            sub_found=1
            break
        fi
        refresh_attempt=$((refresh_attempt + 1))
    done
    echo ""

    if [[ "$sub_found" -eq 1 ]]; then
        # ARM confirmed subscription is visible — re-login to sync CLI subscription list
        # MSAL uses the cached session so browser interaction is usually minimal (click "Continue")
        echo "  Subscription visible — re-authenticating to sync CLI context..."
        # 2>&1 >/dev/null pipes stderr through grep (keeping WARNING: lines) while stdout goes to /dev/null
        AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" 2>&1 >/dev/null | grep "^WARNING:" || true
        if [[ -n "$default_sub_id" ]]; then
            if az account set --subscription "$default_sub_id" 2>/dev/null; then
                echo "  Default subscription: $default_sub_name"
            else
                echo "  Warning: Could not set default subscription $default_sub_name ($default_sub_id)"
                echo "  Run: az account set --subscription $default_sub_id  # $default_sub_name"
            fi
        fi
    else
        local elapsed=$(( refresh_attempt * 5 ))
        echo "  Warning: Subscriptions not yet visible after ${elapsed}s — PIM propagation may still be in progress."
        echo "  When ready, run:"
        echo "    az login --tenant $tenant_id"
        [[ -n "$default_sub_id" ]] && echo "    az account set --subscription $default_sub_id  # $default_sub_name"
    fi
}

# AKS token pre-cache for a kubectl context
# Usage: azpim aks-token [context]
#   default context: kubectl config current-context
_azpim_aks_token() {
    local ctx="${1:-}"

    # Check deps
    for tool in kubectl kubelogin; do
        if ! command -v "$tool" &>/dev/null; then
            echo "Error: '$tool' is not installed"
            return 1
        fi
    done

    # Get context name
    if [[ -z "$ctx" ]]; then
        ctx=$(kubectl config current-context 2>/dev/null)
        if [[ -z "$ctx" ]]; then
            echo "Error: No current kubectl context set"
            return 1
        fi
    fi
    echo "Context: $ctx"

    # Get cluster name for this context
    local cluster_name
    cluster_name=$(kubectl config view --context "$ctx" -o jsonpath="{.contexts[?(@.name==\"$ctx\")].context.cluster}" 2>/dev/null)
    if [[ -z "$cluster_name" ]]; then
        echo "Error: Could not determine cluster name for context '$ctx'"
        return 1
    fi
    _az_dbg "cluster_name=$cluster_name"

    # Get server URL
    local server_url
    server_url=$(kubectl config view --context "$ctx" -o jsonpath="{.clusters[?(@.name==\"$cluster_name\")].cluster.server}" 2>/dev/null)
    if [[ -z "$server_url" ]]; then
        echo "Error: Could not determine server URL for cluster '$cluster_name'"
        return 1
    fi
    _az_dbg "server_url=$server_url"

    # Extract host (strip https://, take up to : or /)
    local host
    host="${server_url#https://}"
    host="${host%%:*}"
    host="${host%%/*}"
    _az_dbg "host=$host"

    # TCP reachability check
    if ! nc -z -w5 "$host" 443 2>/dev/null; then
        echo "Error: AKS endpoint unreachable — check connectivity, e.g. firewall, VPN"
        return 1
    fi

    # Get user entry for context, then extract --server-id value from exec args
    local user_name
    user_name=$(kubectl config view --context "$ctx" -o jsonpath="{.contexts[?(@.name==\"$ctx\")].context.user}" 2>/dev/null)
    _az_dbg "user_name=$user_name"

    local server_id
    server_id=$(kubectl config view --context "$ctx" -o json 2>/dev/null | \
        jq -r --arg u "$user_name" '
            .users[] | select(.name == $u) |
            .user.exec.args // [] |
            . as $args |
            indices("--server-id")[0] as $i |
            if $i != null then $args[$i + 1] else empty end
        ' 2>/dev/null)
    _az_dbg "server_id=$server_id"

    if [[ -z "$server_id" ]]; then
        echo "Error: Could not find --server-id in exec args for context '$ctx'"
        return 1
    fi

    # Get tenant_id from config
    local config_file="$HOME/.config/local/azpim.yaml"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        return 1
    fi
    local tenant_id
    tenant_id=$(yq -r '.tenant_id' "$config_file")

    # Pre-cache token
    echo "Pre-caching AKS token for server-id $server_id..."
    if ! az account get-access-token --resource "$server_id" --tenant "$tenant_id" >/dev/null 2>&1; then
        echo "Error: Failed to acquire AKS token"
        return 1
    fi

    # Switch to context
    kubectl config use-context "$ctx"
    echo "AKS token cached."
}

# Switch kubectl context and refresh AKS token if applicable
# Usage: azctx [context]
#   No arg: pick from available contexts via fzf or numbered list
#   AKS contexts (with kubelogin exec): token is pre-cached
#   Non-AKS contexts: context is switched silently, token step skipped
azctx() {
    _az_parse_debug "$@"
    set -- "${_az_remaining_args[@]}"
    local ctx="${1:-}"

    # If no context given, pick one
    if [[ -z "$ctx" ]]; then
        local contexts
        contexts=(${(f)"$(kubectl config get-contexts -o name 2>/dev/null)"})
        if [[ ${#contexts[@]} -eq 0 ]]; then
            echo "Error: No kubectl contexts found"
            return 1
        fi
        if command -v fzf &>/dev/null; then
            ctx=$(printf '%s\n' "${contexts[@]}" | fzf --prompt="Select context: " --height=~40%)
        else
            for i in "${!contexts[@]}"; do
                echo "  $((i+1))) ${contexts[$i]}"
            done
            printf "Select context [1-%d]: " "${#contexts[@]}"
            read -r choice
            ctx="${contexts[$((choice - 1))]}"
        fi
        [[ -z "$ctx" ]] && return 0
    fi

    # Check if this is an AKS context (has kubelogin exec args with --server-id)
    local user_name
    user_name=$(kubectl config view --context "$ctx" -o jsonpath="{.contexts[?(@.name==\"$ctx\")].context.user}" 2>/dev/null)
    local server_id
    server_id=$(kubectl config view --context "$ctx" -o json 2>/dev/null | \
        jq -r --arg u "$user_name" '
            .users[] | select(.name == $u) |
            .user.exec.args // [] |
            . as $args |
            indices("--server-id")[0] as $i |
            if $i != null then $args[$i + 1] else empty end
        ' 2>/dev/null)

    if [[ -n "$server_id" ]]; then
        # AKS context — delegate to aks-token (which also calls use-context)
        _azpim_aks_token "$ctx"
    else
        # Non-AKS context — just switch
        kubectl config use-context "$ctx"
    fi
}

# ==============================================================================
# Azure VM Bastion Tunnel Management (azvm)
# ==============================================================================

_azvm_state_dir="$HOME/.local/state/azvm"
_azvm_state_file="$_azvm_state_dir/tunnels.json"

# Ensure state directory and file exist
_azvm_init_state() {
    mkdir -p "$_azvm_state_dir"
    if [[ ! -f "$_azvm_state_file" ]]; then
        echo '[]' > "$_azvm_state_file"
    fi
}

# Remove entries whose PIDs are no longer alive
_azvm_cleanup() {
    _azvm_init_state
    local result='[]'
    local count
    count=$(jq 'length' "$_azvm_state_file")
    for (( i=0; i<count; i++ )); do
        local pid
        pid=$(jq -r ".[$i].pid" "$_azvm_state_file")
        if kill -0 "$pid" 2>/dev/null; then
            result=$(echo "$result" | jq --argjson entry "$(jq ".[$i]" "$_azvm_state_file")" '. + [$entry]')
        fi
    done
    _azvm_write_state "$result"
}

# Write state atomically
_azvm_write_state() {
    local content="$1"
    local tmp_file="${_azvm_state_file}.tmp"
    echo "$content" > "$tmp_file" && mv "$tmp_file" "$_azvm_state_file"
}

# Get VM config from azpim.yaml
_azvm_get_config() {
    local config_file="$HOME/.config/local/azpim.yaml"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        return 1
    fi
    echo "$config_file"
}

# Connect to a VM via bastion tunnel
# Usage: _azvm_connect [vm-name]
_azvm_connect() {
    local config_file
    config_file=$(_azvm_get_config) || return 1

    for tool in az yq jq; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: '$tool' is not installed"
            return 1
        fi
    done

    _azvm_cleanup

    # Build VM list
    local vm_count default_resource_port
    vm_count=$(yq -r '.vms | length' "$config_file")
    default_resource_port=$(yq -r '.defaults.resource_port // 3389' "$config_file")

    if [[ "$vm_count" -eq 0 ]]; then
        echo "Error: No VMs configured in $config_file"
        return 1
    fi

    local vm_names=()
    for (( i=0; i<vm_count; i++ )); do
        local name
        name=$(yq -r ".vms[$i].name" "$config_file")
        vm_names+=("$name")
    done

    # VM selection: direct arg > fzf > numbered list
    local selected
    if [[ -n "${1:-}" ]]; then
        selected="$1"
    elif command -v fzf &>/dev/null; then
        selected=$(printf '%s\n' "${vm_names[@]}" | fzf --prompt="Select VM: " --height=~40%)
    else
        for i in "${!vm_names[@]}"; do
            echo "  $((i+1))) ${vm_names[$i]}"
        done
        printf "Select VM [1-%d]: " "${#vm_names[@]}"
        read -r choice
        selected="${vm_names[$((choice - 1))]}"
    fi

    if [[ -z "$selected" ]]; then
        echo "No VM selected"
        return 0
    fi

    # Find VM index
    local vm_idx=-1
    for (( i=0; i<vm_count; i++ )); do
        local name
        name=$(yq -r ".vms[$i].name" "$config_file")
        if [[ "$name" == "$selected" ]]; then
            vm_idx=$i
            break
        fi
    done

    if [[ "$vm_idx" -eq -1 ]]; then
        echo "Error: VM '$selected' not found in config"
        return 1
    fi

    # Read VM config
    local vm_subscription resource_id bastion_name bastion_rg local_port resource_port username password
    vm_subscription=$(yq -r ".vms[$vm_idx].subscription // \"\"" "$config_file")
    resource_id=$(yq -r ".vms[$vm_idx].resource_id" "$config_file")
    bastion_name=$(yq -r ".vms[$vm_idx].bastion_name" "$config_file")
    bastion_rg=$(yq -r ".vms[$vm_idx].bastion_rg" "$config_file")
    local_port=$(yq -r ".vms[$vm_idx].local_port" "$config_file")
    resource_port=$(yq -r ".vms[$vm_idx].resource_port // \"$default_resource_port\"" "$config_file")
    username=$(yq -r ".vms[$vm_idx].username // \"\"" "$config_file")
    password=$(yq -r ".vms[$vm_idx].password // \"\"" "$config_file")

    # Resolve subscription name to ID
    local vm_sub_id=""
    if [[ -n "$vm_subscription" ]]; then
        vm_sub_id=$(_az_run az account list --query "[?name=='$vm_subscription'].id | [0]" -o tsv)
        if [[ -z "$vm_sub_id" ]]; then
            echo "Error: Subscription '$vm_subscription' not found in az account list"
            return 1
        fi
        echo "Using subscription: $vm_subscription"
        _az_dbg "vm_sub_id=$vm_sub_id"
    fi

    # Build --subscription args for az commands that support it (az vm)
    local vm_sub_args=()
    [[ -n "$vm_sub_id" ]] && vm_sub_args=(--subscription "$vm_sub_id")

    # Check if tunnel already exists for this VM
    local existing_pid
    existing_pid=$(jq -r --arg name "$selected" '.[] | select(.name == $name) | .pid' "$_azvm_state_file")
    if [[ -n "$existing_pid" ]]; then
        echo "Tunnel already active for $selected (PID $existing_pid, port $local_port)"
        return 0
    fi

    # Check if VM is running, start if needed
    echo "Checking VM power state..."
    local power_state
    power_state=$(_az_run az vm get-instance-view \
        --ids "$resource_id" "${vm_sub_args[@]}" \
        --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]" \
        -o tsv)
    _az_dbg "power_state=$power_state"

    if [[ "$power_state" != "VM running" ]]; then
        echo "VM is $power_state — starting..."
        _az_run az vm start --ids "$resource_id" "${vm_sub_args[@]}" --no-wait

        local vm_wait=0
        while [[ $vm_wait -lt 30 ]]; do
            sleep 5
            power_state=$(_az_run az vm get-instance-view \
                --ids "$resource_id" "${vm_sub_args[@]}" \
                --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]" \
                -o tsv)
            if [[ "$power_state" == "VM running" ]]; then
                echo "VM is running"
                break
            fi
            echo "  Waiting for VM to start ($power_state)..."
            vm_wait=$((vm_wait + 1))
        done
        if [[ "$power_state" != "VM running" ]]; then
            echo "Error: VM did not start within 150 seconds"
            return 1
        fi
    else
        echo "VM is running"
    fi

    # Check if local port is already in use
    if nc -z localhost "$local_port" 2>/dev/null; then
        echo "Error: Port $local_port is already in use"
        echo "  Check: lsof -i :$local_port"
        return 1
    fi

    # Start bastion tunnel in background
    # az network bastion tunnel (extension) doesn't support --subscription,
    # so we briefly set the subscription context and restore it after launch
    echo "Starting bastion tunnel to $selected on localhost:$local_port..."
    local prev_sub_id=""
    if [[ -n "$vm_sub_id" ]]; then
        prev_sub_id=$(_az_run az account show --query id -o tsv)
        _az_run az account set --subscription "$vm_sub_id"
    fi

    if [[ "$_az_debug" -eq 1 ]]; then
        az network bastion tunnel \
            --name "$bastion_name" \
            --resource-group "$bastion_rg" \
            --target-resource-id "$resource_id" \
            --resource-port "$resource_port" \
            --port "$local_port" &
    else
        az network bastion tunnel \
            --name "$bastion_name" \
            --resource-group "$bastion_rg" \
            --target-resource-id "$resource_id" \
            --resource-port "$resource_port" \
            --port "$local_port" &> /dev/null &
    fi
    local tunnel_pid=$!
    disown

    # Restore previous subscription immediately
    if [[ -n "$prev_sub_id" ]]; then
        _az_run az account set --subscription "$prev_sub_id"
    fi

    # Wait for tunnel to be ready (port listening) or process to die
    echo "  Waiting for tunnel to be ready..."
    local tunnel_wait=0
    while [[ $tunnel_wait -lt 30 ]]; do
        if ! kill -0 "$tunnel_pid" 2>/dev/null; then
            echo "Error: Tunnel process died (PID $tunnel_pid)"
            return 1
        fi
        if nc -z localhost "$local_port" 2>/dev/null; then
            echo "  Tunnel ready"
            break
        fi
        sleep 2
        tunnel_wait=$((tunnel_wait + 1))
    done
    if [[ $tunnel_wait -ge 30 ]]; then
        echo "Error: Tunnel did not become ready within 60 seconds"
        kill "$tunnel_pid" 2>/dev/null
        return 1
    fi

    # Record in state
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local state
    state=$(jq --arg name "$selected" \
        --argjson pid "$tunnel_pid" \
        --arg port "$local_port" \
        --arg started "$now" \
        '. + [{"name": $name, "pid": $pid, "port": $port, "started": $started}]' \
        "$_azvm_state_file")
    _azvm_write_state "$state"

    echo "Tunnel active: $selected -> localhost:$local_port (PID $tunnel_pid)"

    # Generate and open RDP file
    local rdp_file="$TMPDIR/azvm-${selected}.rdp"
    echo "full address:s:localhost:${local_port}" > "$rdp_file"
    if [[ -n "$username" ]]; then
        echo "username:s:${username}" >> "$rdp_file"
    fi
    if [[ -n "$password" ]]; then
        echo "password 51:b:${password}" >> "$rdp_file"
        echo "Warning: Password is stored in config — this is insecure"
    fi

    echo "Opening RDP session..."
    open "$rdp_file"
}

# List active tunnels
_azvm_ls() {
    _azvm_cleanup
    local count
    count=$(jq 'length' "$_azvm_state_file")

    if [[ "$count" -eq 0 ]]; then
        echo "No active tunnels"
        return 0
    fi

    printf "%-20s  %-8s  %-6s  %s\n" "VM" "PID" "PORT" "STARTED"
    printf "%-20s  %-8s  %-6s  %s\n" "----" "---" "----" "-------"
    for (( i=0; i<count; i++ )); do
        local name pid port started
        name=$(jq -r ".[$i].name" "$_azvm_state_file")
        pid=$(jq -r ".[$i].pid" "$_azvm_state_file")
        port=$(jq -r ".[$i].port" "$_azvm_state_file")
        started=$(jq -r ".[$i].started" "$_azvm_state_file")
        printf "%-20s  %-8s  %-6s  %s\n" "$name" "$pid" "$port" "$started"
    done
}

# Kill a specific tunnel by name or port
_azvm_kill() {
    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Usage: azvm kill <vm-name|port>"
        return 1
    fi

    _azvm_cleanup

    # Find by name or port
    local pid
    pid=$(jq -r --arg t "$target" '.[] | select(.name == $t or .port == $t) | .pid' "$_azvm_state_file")

    if [[ -z "$pid" ]]; then
        echo "Error: No tunnel found for '$target'"
        return 1
    fi

    local name
    name=$(jq -r --arg t "$target" '.[] | select(.name == $t or .port == $t) | .name' "$_azvm_state_file")

    kill "$pid" 2>/dev/null
    echo "Killed tunnel for $name (PID $pid)"

    # Remove from state
    local state
    state=$(jq --arg t "$target" '[.[] | select(.name != $t and .port != $t)]' "$_azvm_state_file")
    _azvm_write_state "$state"
}

# Kill all tunnels
_azvm_kill_all() {
    _azvm_cleanup
    local count
    count=$(jq 'length' "$_azvm_state_file")

    if [[ "$count" -eq 0 ]]; then
        echo "No active tunnels"
        return 0
    fi

    for (( i=0; i<count; i++ )); do
        local name pid
        name=$(jq -r ".[$i].name" "$_azvm_state_file")
        pid=$(jq -r ".[$i].pid" "$_azvm_state_file")
        kill "$pid" 2>/dev/null
        echo "Killed tunnel for $name (PID $pid)"
    done

    _azvm_write_state '[]'
}

# Main azvm dispatcher
azvm() {
    _az_parse_debug "$@"
    set -- "${_az_remaining_args[@]}"
    local subcmd="${1:-connect}"
    shift 2>/dev/null

    case "$subcmd" in
        connect)    _azvm_connect "$@" ;;
        ls)         _azvm_ls "$@" ;;
        kill)       _azvm_kill "$@" ;;
        kill-all)   _azvm_kill_all "$@" ;;
        *)
            echo "Usage: azvm [-d|--debug] [connect|ls|kill|kill-all]"
            echo ""
            echo "Commands:"
            echo "  connect [vm-name]     Select a VM and start bastion tunnel (default)"
            echo "  ls                    List active tunnels"
            echo "  kill <name|port>      Kill a specific tunnel"
            echo "  kill-all              Kill all tunnels"
            echo ""
            echo "Options:"
            echo "  -d, --debug    Show debug output"
            echo "  AZURE_DEBUG=1  Enable debug via env var"
            return 1
            ;;
    esac
}
