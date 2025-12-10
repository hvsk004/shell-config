#!/bin/bash
set -e

# --- 0. Check for root user ---
if [[ $EUID -eq 0 ]] && [[ "$1" != "--root" ]]; then
  echo "⚠️  WARNING: You are running this script as root!"
  echo "This will configure zsh for the root user, which is usually not intended."
  echo ""
  echo "If you meant to run this for a regular user, exit and run:"
  echo "  ./zsh-setup.sh"
  echo ""
  echo "If you really want to configure zsh for root, run:"
  echo "  ./zsh-setup.sh --root"
  exit 1
fi

# --- 1. Backup existing .zshrc ---
if [ -f ~/.zshrc ]; then
  echo "Backing up existing .zshrc to .zshrc.bak..."
  cp ~/.zshrc ~/.zshrc.bak
fi

# --- 1. Install Zsh and Git ---url ---
PACKAGES="zsh git curl"

install_packages() {
  if command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y $PACKAGES
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y $PACKAGES
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y $PACKAGES
  else
    echo "Error: No supported package manager found (apt/dnf/yum)"
    exit 1
  fi
}

# Install if zsh or git is missing
if ! command -v zsh >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  echo "Installing required packages..."
  install_packages
fi

# --- 2. Install Plugins ---
# We store plugins in the user's home directory
PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$PLUGIN_DIR"

if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
fi

# --- 3. Configure .zshrc ---
if ! grep -q "zsh-autosuggestions" ~/.zshrc 2>/dev/null; then

# (A) Hardcode the plugin path so Root can find the User's plugins
echo "export ZSH_PLUGIN_ROOT='$HOME/.zsh'" >> ~/.zshrc

# (B) Append the main configuration
cat << 'RC' >> ~/.zshrc

# --- History Config ---
# If root, use a temp history file to avoid locking the user's file
if [[ $UID -eq 0 ]]; then
   HISTFILE="/root/.zsh_history_temp"
else
   HISTFILE="$HOME/.zsh_history"
fi
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# --- Prompt ---
autoload -U colors && colors
# Red prompt for Root, Green for User
if [[ $UID -eq 0 ]]; then
  PROMPT="%{$fg[red]%}%n@%m%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} # "
else
  PROMPT="%{$fg[green]%}%n@%m%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} $ "
fi

# --- ALIASES ---
# 1. The Super-User Zsh alias (Run zsh as root, but use MY config)
# Prevent alias/function conflicts
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
source "$ZSH_PLUGIN_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGIN_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

RC
fi

# --- 4. Switch Shell ---
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Switching default shell to Zsh..."
  sudo chsh -s "$(which zsh)" "$USER"
fi


echo "✔ Setup complete. Logout and SSH back in."