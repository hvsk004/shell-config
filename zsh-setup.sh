#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "🚀 Starting Zsh setup..."

# --- 1. Install System Packages ---
PACKAGES="zsh git curl fzf zoxide"

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

# Install if zsh, git, curl, fzf, or zoxide is missing
if ! command -v zsh >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1 || ! command -v zoxide >/dev/null 2>&1; then
  echo "📦 Installing required system packages..."
  install_packages
fi

# --- 2. Install Starship Prompt ---
if ! command -v starship >/dev/null 2>&1; then
  echo "✨ Installing Starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# --- 3. Install Zsh Plugins ---
PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$PLUGIN_DIR"

if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  echo "📥 Cloning zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  echo "📥 Cloning zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
fi

# --- 4. Copy Configuration Files ---
echo "⚙️  Configuring files..."

# Starship Config
mkdir -p ~/.config

if [ -f ~/.config/starship.toml ]; then
  echo "📂 Backing up existing starship.toml to starship.toml.bak..."
  cp ~/.config/starship.toml ~/.config/starship.toml.bak
fi
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
  cp "$SCRIPT_DIR/starship.toml" ~/.config/starship.toml
  echo "✅ Copied starship.toml"
else
  echo "⚠️  Warning: starship.toml not found in $SCRIPT_DIR"
fi

# Zshrc Config
if [ -f ~/.zshrc ]; then
  echo "📂 Backing up existing .zshrc to .zshrc.bak..."
  cp ~/.zshrc ~/.zshrc.bak
fi

if [ -f "$SCRIPT_DIR/.zshrc" ]; then
  cp "$SCRIPT_DIR/.zshrc" ~/.zshrc
  echo "✅ Copied .zshrc"
else
  echo "⚠️  Warning: .zshrc not found in $SCRIPT_DIR"
fi

# --- 5. Switch Shell ---
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "🔄 Switching default shell to Zsh..."
  sudo chsh -s "$(which zsh)" "$USER"
fi

echo "✔ Setup complete. Logout and SSH back in to see changes!"
