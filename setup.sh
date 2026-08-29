#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Error: specify which host to apply." >&2
  echo "Usage: $0 <host>" >&2
  echo "  e.g. $0 powehi" >&2
  echo "       $0 local   (cp hosts/local.example.nix hosts/local.nix && \$EDITOR hosts/local.nix first)" >&2
  exit 1
fi
HOST="$1"

echo "Setting up your Mac..."

# Xcode Command Line Tools
if ! command -v xcode-select &> /dev/null || ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode installation, then run this script again."
    exit 0
fi

# Nix (Determinate Systems installer)
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Apply nix-darwin configuration
echo "Applying nix-darwin configuration..."
~/dotfiles/apply.sh "$HOST"

echo "Tip: After setup, use 'nixup' (powehi only) or 'task apply HOST=$HOST' to apply changes."

echo ""
echo "Setup complete! Open a new terminal to start."
