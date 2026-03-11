# ZSH Configuration

## Azure Helpers (`zsh.d/66-azure-helpers.zsh`)

Inspired by: [Automate Azure PIM Role Activation for Entra ID and RBAC with PowerShell and Bash](https://corti.com/automate-azure-pim-role-activation-for-entra-id-and-rbac-with-powershell-and-bash/)

Shell functions for daily Azure PIM RBAC role activation and subscription management — no Azure Portal needed.

### Commands

| Command | Description |
|---------|-------------|
| `azpim` | **Az**ure **PIM** — authenticate and activate all PIM roles for the day |
| `azpim RoleName` | Activate only roles matching the given name(s) |
| `azpim -f` | Force re-activation even if roles are already active |
| `azpim -v` | Verbose output (show progress detail) |
| `azpim -d` | Debug output (verbose + raw API payloads) |
| `azpim aks-token [context]` | Pre-cache AKS token for a kubectl context (default: current context) |
| `azctx [context]` | Switch kubectl context; refreshes AKS token automatically if applicable |
| `azgs` | **Az**ure **G**et **S**ubscription — print current default subscription name (no API call) |
| `azss <name\|id>` | **Az**ure **S**et **S**ubscription — switch active subscription |

### How `azpim` works

1. Authenticates via `az login --allow-no-subscriptions` (browser/MFA)
2. For each configured subscription and role (optionally filtered by name):
   - Skips if already active (with hint to use `-f` to force)
   - Deactivates the role (if currently active and `-f` is passed)
   - Activates the role via the ARM PIM API
3. Polls ARM REST until the subscription is visible (PIM propagation)
4. Re-authenticates (`az login`) to sync the CLI subscription list
5. Sets the configured default subscription

### How `azpim aks-token` works

1. Resolves the kubectl context (arg or current)
2. Checks AKS endpoint reachability (TCP port 443)
3. Extracts `--server-id` from the context's kubelogin exec args
4. Pre-caches an AAD token for that server-id via `az account get-access-token`
5. Switches to the target context

### Configuration

Config file: `~/.config/local/azpim.yaml` (not committed — local only)

```yaml
tenant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
reason: "Cloud operations"
duration: "PT12H"   # ISO 8601 duration — PT8H, PT12H, P1D, etc.

subscriptions:
  - name: my-subscription-nonprod
    id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    default: true
    roles:
      - MyCustomRole-NonProd

  - name: my-subscription-prod
    id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    roles:
      - MyCustomRole-Prod
```

**Notes:**
- Exactly one subscription may be marked `default: true` — this becomes the active `az account` after `azpim` completes.
- Role names must match exactly as they appear in Azure PIM.
- The file is in `~/.config/local/` which is gitignored — tenant IDs and subscription IDs stay off-repo.
- Run `azpim init` to generate the config interactively if starting from scratch.

### Dependencies

```
az          # Azure CLI
yq          # YAML processor
jq          # JSON processor
curl        # HTTP client (for ARM REST API calls)
kubectl     # Kubernetes CLI (for azpim aks-token)
kubelogin   # AAD kubeconfig plugin (for azpim aks-token)
fzf         # Fuzzy finder — optional, azvm falls back to numbered list
```

Install via Homebrew: `brew install azure-cli yq jq kubectl kubelogin`

### Standalone usage (no dotfiles)

The file is self-contained — source it directly without installing the full dotfiles:

```zsh
# One-time
source /path/to/66-azure-helpers.zsh

# Permanent — add to ~/.zshrc
echo 'source /path/to/66-azure-helpers.zsh' >> ~/.zshrc
```

The only required setup is the config file at `~/.config/local/azpim.yaml` (see Configuration above).

---

## Docker

A `Dockerfile` at the repo root builds a full shell environment with all Azure tools pre-installed.

```bash
# Build (native arch)
docker build -t dotfiles .

# Build for amd64 from Apple Silicon (or any cross-arch)
docker buildx build --platform linux/amd64 -t dotfiles .

# Build and push multi-arch to a registry
docker buildx build --platform linux/amd64,linux/arm64 -t myregistry/dotfiles:latest --push .

# Run
docker run -it dotfiles

# Azure login inside the container (device code flow)
az login --use-device-code
```

### Exporting an image for a specific platform

`docker buildx build` with `--platform` does not load the image into the local store by default. Use `--load` first, then `docker save`:

```bash
# Build for amd64 and load into local Docker store
docker buildx build --platform linux/amd64 --load -t dotfiles:amd64 .

# Export to a compressed archive
docker save dotfiles:amd64 | gzip > dotfiles-amd64.tar.gz

# On the target machine — load and run
docker load < dotfiles-amd64.tar.gz
docker run -it dotfiles:amd64
```

---

## TODOs

- **Windows App integration for `azvm`**: The Windows App (formerly Microsoft Remote Desktop) stores PC bookmarks in a SQLite database at `~/Library/Containers/com.microsoft.rdc.macos/Data/Library/Application Support/com.microsoft.rdc.macos/com.microsoft.rdc.macos.db`. `azvm connect` could read connections directly from there (table `ZBOOKMARK`) so you don't need to duplicate VM entries in `azpim.yaml`.
