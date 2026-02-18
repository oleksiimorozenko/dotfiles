# ==============================================================================
# Azure Helper Functions
# ==============================================================================

# Azure Good Morning — activate PIM RBAC roles for the day
azgm() {
    local config_file="$HOME/.config/zsh/local/azgm.yaml"

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
    echo "Logging in to Azure tenant $tenant_id..."
    if ! AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" --allow-no-subscriptions; then
        echo "Error: Azure login failed"
        return 1
    fi

    # Get principal ID
    local principal_id
    principal_id=$(az ad signed-in-user show --query id -o tsv)
    if [[ -z "$principal_id" ]]; then
        echo "Error: Could not determine signed-in user principal ID"
        return 1
    fi
    echo "Principal ID: $principal_id"
    echo ""

    # Get management API token explicitly scoped to our tenant
    local mgmt_token
    mgmt_token=$(az account get-access-token --tenant "$tenant_id" --resource "https://management.azure.com" --query accessToken -o tsv)
    if [[ -z "$mgmt_token" ]]; then
        echo "Error: Could not acquire management API token for tenant $tenant_id"
        return 1
    fi

    local arm_base="https://management.azure.com"

    # Iterate subscriptions and roles
    local sub_count role_count activated=0 failed=0
    sub_count=$(yq -r '.subscriptions | length' "$config_file")

    for (( s=0; s<sub_count; s++ )); do
        local sub_name sub_id
        sub_name=$(yq -r ".subscriptions[$s].name" "$config_file")
        sub_id=$(yq -r ".subscriptions[$s].id" "$config_file")
        role_count=$(yq -r ".subscriptions[$s].roles | length" "$config_file")

        echo "--- $sub_name ($sub_id) ---"

        # Fetch eligible assignments for this subscription
        local eligible_assignments eligible_url
        eligible_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?\$filter=asTarget()&api-version=2020-10-01"
        eligible_assignments=$(curl -s -H "Authorization: Bearer $mgmt_token" "$eligible_url")

        if [[ -z "$eligible_assignments" ]] || echo "$eligible_assignments" | jq -e '.error' &>/dev/null; then
            echo "  Warning: Could not fetch eligible assignments"
            echo "  $(echo "$eligible_assignments" | jq -r '.error.message // empty')"
        fi

        for (( r=0; r<role_count; r++ )); do
            local role_name role_def_id
            role_name=$(yq -r ".subscriptions[$s].roles[$r]" "$config_file")

            echo "  Role: $role_name"

            # Look up role definition ID from eligible assignments
            role_def_id=$(echo "$eligible_assignments" | jq -r \
                --arg name "$role_name" \
                '[.value[] | select(.properties.expandedProperties.roleDefinition.displayName == $name)] | first | .properties.expandedProperties.roleDefinition.id // empty')

            if [[ -z "$role_def_id" ]]; then
                echo "    Error: No eligible assignment found for '$role_name'"
                echo "    (Check the role name matches exactly in Azure)"
                failed=$((failed + 1))
                continue
            fi

            # Always deactivate first to ensure a fresh activation window
            echo "    Deactivating (if active)..."
            local deactivate_guid deactivate_body deactivate_tmp deactivate_url
            deactivate_guid=$(uuidgen | tr '[:upper:]' '[:lower:]')
            deactivate_body=$(jq -n \
                --arg pid "$principal_id" \
                --arg rdid "/subscriptions/$sub_id/providers/Microsoft.Authorization/roleDefinitions/$role_def_id" \
                --arg reason "$reason" \
                '{
                    "Properties": {
                        "PrincipalId": $pid,
                        "RoleDefinitionId": $rdid,
                        "RequestType": "SelfDeactivate",
                        "Justification": $reason
                    }
                }')

            deactivate_tmp=$(mktemp)
            echo "$deactivate_body" > "$deactivate_tmp"
            deactivate_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$deactivate_guid?api-version=2020-10-01"

            local deactivate_resp
            deactivate_resp=$(curl -s -X PUT \
                -H "Authorization: Bearer $mgmt_token" \
                -H "Content-Type: application/json" \
                -d "@$deactivate_tmp" "$deactivate_url")
            rm -f "$deactivate_tmp"

            # Activate fresh
            local activate_guid activate_body activate_tmp activate_url
            activate_guid=$(uuidgen | tr '[:upper:]' '[:lower:]')
            activate_body=$(jq -n \
                --arg pid "$principal_id" \
                --arg rdid "/subscriptions/$sub_id/providers/Microsoft.Authorization/roleDefinitions/$role_def_id" \
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

            activate_tmp=$(mktemp)
            echo "$activate_body" > "$activate_tmp"
            activate_url="$arm_base/subscriptions/$sub_id/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$activate_guid?api-version=2020-10-01"

            local activate_resp
            activate_resp=$(curl -s -X PUT \
                -H "Authorization: Bearer $mgmt_token" \
                -H "Content-Type: application/json" \
                -d "@$activate_tmp" "$activate_url")
            rm -f "$activate_tmp"

            if echo "$activate_resp" | jq -e '.error' &>/dev/null; then
                echo "    Error: Activation failed"
                echo "    $(echo "$activate_resp" | jq -r '.error.message // empty')"
                failed=$((failed + 1))
            else
                echo "    Activated ($duration)"
                activated=$((activated + 1))
            fi
        done
        echo ""
    done

    echo "Done: $activated activated, $failed failed"

    # Refresh account list now that PIM roles are active (subscriptions should appear)
    echo ""
    echo "Refreshing subscription list..."
    az account clear 2>/dev/null
    AZURE_CORE_LOGIN_EXPERIENCE_V2=off az login --tenant "$tenant_id" --only-show-errors > /dev/null 2>&1

    # Set default subscription if configured
    local default_sub_id
    default_sub_id=$(yq -r '.subscriptions[] | select(.default == true) | .id' "$config_file")
    if [[ -n "$default_sub_id" ]]; then
        az account set --subscription "$default_sub_id" 2>/dev/null
        echo "Default subscription set to: $default_sub_id"
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

# Get VM config from azgm.yaml
_azvm_get_config() {
    local config_file="$HOME/.config/zsh/local/azgm.yaml"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        return 1
    fi
    echo "$config_file"
}

# Connect to a VM via bastion tunnel
_azvm_connect() {
    local config_file
    config_file=$(_azvm_get_config) || return 1

    for tool in az yq jq fzf; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: '$tool' is not installed"
            return 1
        fi
    done

    _azvm_cleanup

    # Build VM list for fzf
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

    # fzf picker
    local selected
    selected=$(printf '%s\n' "${vm_names[@]}" | fzf --prompt="Select VM: " --height=~40%)
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
    local resource_id bastion_name bastion_rg local_port resource_port username password
    resource_id=$(yq -r ".vms[$vm_idx].resource_id" "$config_file")
    bastion_name=$(yq -r ".vms[$vm_idx].bastion_name" "$config_file")
    bastion_rg=$(yq -r ".vms[$vm_idx].bastion_rg" "$config_file")
    local_port=$(yq -r ".vms[$vm_idx].local_port" "$config_file")
    resource_port=$(yq -r ".vms[$vm_idx].resource_port // \"$default_resource_port\"" "$config_file")
    username=$(yq -r ".vms[$vm_idx].username // \"\"" "$config_file")
    password=$(yq -r ".vms[$vm_idx].password // \"\"" "$config_file")

    # Check if tunnel already exists for this VM
    local existing_pid
    existing_pid=$(jq -r --arg name "$selected" '.[] | select(.name == $name) | .pid' "$_azvm_state_file")
    if [[ -n "$existing_pid" ]]; then
        echo "Tunnel already active for $selected (PID $existing_pid, port $local_port)"
        return 0
    fi

    # Start bastion tunnel in background
    echo "Starting bastion tunnel to $selected on localhost:$local_port..."
    az network bastion tunnel \
        --name "$bastion_name" \
        --resource-group "$bastion_rg" \
        --target-resource-id "$resource_id" \
        --resource-port "$resource_port" \
        --port "$local_port" &> /dev/null &
    local tunnel_pid=$!
    disown

    # Wait briefly to catch immediate failures
    sleep 2
    if ! kill -0 "$tunnel_pid" 2>/dev/null; then
        echo "Error: Tunnel process died immediately (PID $tunnel_pid)"
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
    local subcmd="${1:-connect}"
    shift 2>/dev/null

    case "$subcmd" in
        connect)    _azvm_connect "$@" ;;
        ls)         _azvm_ls "$@" ;;
        kill)       _azvm_kill "$@" ;;
        kill-all)   _azvm_kill_all "$@" ;;
        *)
            echo "Usage: azvm [connect|ls|kill|kill-all]"
            echo ""
            echo "Commands:"
            echo "  connect     Select a VM and start bastion tunnel (default)"
            echo "  ls          List active tunnels"
            echo "  kill <name|port>  Kill a specific tunnel"
            echo "  kill-all    Kill all tunnels"
            return 1
            ;;
    esac
}
