# --- Plugins Root ---
export ZSH_PLUGIN_ROOT="$HOME/.zsh"

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
alias mv="mv -i"
alias rm="rm -i"

# --- Load Plugins ---
# Try to load plugins if they exist
if [ -f "$ZSH_PLUGIN_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$ZSH_PLUGIN_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$ZSH_PLUGIN_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_PLUGIN_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- Starship Initialization ---
# This MUST be at the end of the file
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
