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
# Note: We do NOT install fzf or zoxide via apt because Ubuntu repos are often too old
# to support features like "fzf --zsh" or recent zoxide flags.
PACKAGES="zsh git curl tmux bat"

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

# Helper to check if a command exists (handling bat/batcat mapping)
is_missing() {
  if [[ "$1" == "bat" ]]; then
    ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1
  else
    ! command -v "$1" >/dev/null 2>&1
  fi
}

# Check if any package is missing
MISSING_PACKAGES=""
for pkg in $PACKAGES; do
  if is_missing "$pkg"; then
    MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
  fi
done

if [ -n "$MISSING_PACKAGES" ]; then
  echo "📦 Installing missing packages:$MISSING_PACKAGES..."
  PACKAGES="$MISSING_PACKAGES"
  install_packages
fi

# --- 2. Install Tools (Latest Versions) ---

# Install FZF (Git method ensures latest version for --zsh support)
if [ ! -d "$HOME/.fzf" ]; then
  echo "🔍 Installing FZF (Latest)..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
fi

# Install Zoxide (Official script)
if ! command -v zoxide >/dev/null 2>&1; then
  echo "🚀 Installing Zoxide..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# --- 3. Install Starship Prompt ---
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

# --- 5. Copy Configuration Files ---
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

# Tmux Config
if [ -f ~/.tmux.conf ]; then
  echo "📂 Backing up existing .tmux.conf to .tmux.conf.bak..."
  cp ~/.tmux.conf ~/.tmux.conf.bak
fi

if [ -f "$SCRIPT_DIR/tmux.conf" ]; then
  cp "$SCRIPT_DIR/tmux.conf" ~/.tmux.conf
  echo "✅ Copied .tmux.conf"
else
  echo "⚠️  Warning: tmux.conf not found in $SCRIPT_DIR"
fi

# --- 6. Switch Shell ---
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "🔄 Switching default shell to Zsh..."
  sudo chsh -s "$(which zsh)" "$USER"
fi

echo "✔ Setup complete. Logout and SSH back in to see changes!"
