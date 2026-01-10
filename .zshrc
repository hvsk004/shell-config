# --- Plugins Root ---
export ZSH_PLUGIN_ROOT="$HOME/.zsh"

# --- PATH ---
# Use Zsh's 'path' array to avoid duplicates and ensure precedence.
# This prepends to PATH only if not already present.
path=("$HOME/.local/bin" "$HOME/.fzf/bin" $path)
export PATH

# --- History Config ---
# If root, use a temp history file to avoid locking the user's file
if [[ $UID -eq 0 ]]; then
   HISTFILE="/root/.zsh_history_temp"
else
   HISTFILE="$HOME/.zsh_history"
fi
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY

# --- ALIASES ---
# 1. The Super-User Zsh alias (Run zsh as root, but use MY config)
unalias suzsh 2>/dev/null
suzsh() {
    # 1. Check if we are using Ghostty
    if [[ "$TERM" == "xterm-ghostty" ]]; then
        # 2. Check if Root has the terminfo. 
        # If 'sudo infocmp' fails, install it.
        if ! sudo infocmp "$TERM" > /dev/null 2>&1; then
            echo "👻 First time setup: Installing Ghostty terminfo for root..."
            infocmp "$TERM" | sudo tic -x -
        fi
    fi

    # 3. Run the command
    sudo ZDOTDIR=$HOME zsh
}

# 2. Python defaults
alias python="python3"
alias pip="pip3"

# 3. Listing and File Ops
alias ll="ls -lh"        # List long format, human readable sizes
alias la="ls -lah"       # List all (including hidden)
alias l="ls -CF"
alias grep="grep --color=auto"

# 4. Safety (interactive mode prevents accidental deletions)
alias cp="cp -i"

# 5. Ubuntu Bat (batcat) fix
if command -v batcat > /dev/null; then
  alias bat="batcat"
fi
alias mv="mv -i"
alias rm="rm -i"

# --- Custom Docker/Backend Aliases ---
# dlogs: Tail logs for a specific container (fuzzy find if no arg)
dlogs() {
    local container=$1
    local since_time="${2:-1m}"  # Default fallback to 1 minute

    if [[ -z "$container" ]]; then
        # Fetch names of all running containers
        container=$(docker ps --format "{{.Names}}" | fzf --height 40% --layout=reverse --border --header "Select Container for Logs")
    fi

    # If a container was selected or provided, tail the logs
    if [[ -n "$container" ]]; then
        echo "Viewing logs for: $container (since $since_time)..."
        docker logs -f "$container" --since "$since_time"
    fi
}

# --- Docker Compose Helpers ---

# 1. dcr: Restart a specific service (fuzzy find if no arg)
dcr() {
    local service=$1
    if [[ -z "$service" ]]; then
        # Fetch service names from docker-compose.yml
        service=$(docker compose config --services | fzf --height 40% --layout=reverse --border --header "Select Service to Restart")
    fi
    
    # If a service was selected or provided, restart it
    if [[ -n "$service" ]]; then
        docker compose restart "$service"
    fi
}

# 2. dcup: Up a specific service or the whole stack
dcup() {
    local service=$1
    if [[ -n "$service" ]]; then
        docker compose up -d "$service"
    else
        echo "🚀 Starting entire stack..."
        docker compose up -d
    fi
}

# 3. dcdown: Down a specific service or the whole stack
dcdown() {
    local service=$1
    if [[ -n "$service" ]]; then
        docker compose stop "$service" && docker compose rm -f "$service"
    else
        echo "🛑 Stopping entire stack..."
        docker compose down
    fi
}

alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"


# --- Load Plugins ---
# Try to load plugins if they exist
if [ -f "$ZSH_PLUGIN_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$ZSH_PLUGIN_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$ZSH_PLUGIN_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_PLUGIN_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- FZF ---
if command -v fzf >/dev/null 2>&1; then
  # Completion and keybindings (if using newer fzf)
  source <(fzf --zsh)
fi

# --- Zoxide (Better cd) ---
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --- Starship Initialization ---
# This MUST be at the end of the file
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
