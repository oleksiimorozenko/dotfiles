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
