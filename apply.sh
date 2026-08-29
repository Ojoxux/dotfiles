#!/bin/bash
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Error: This script is only for macOS (Darwin)"
  exit 1
fi

if ! command -v nix &> /dev/null; then
  echo "Error: Nix is not installed. Run ~/dotfiles/setup.sh first."
  exit 1
fi

if ! command -v brew &> /dev/null; then
  echo "Error: Homebrew is not installed. Run ~/dotfiles/setup.sh first."
  exit 1
fi

UPDATE=0
HOST=""

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    *) HOST="$arg" ;;
  esac
done

if [[ -z "$HOST" ]]; then
  echo "Error: no host specified." >&2
  echo "Usage: $0 <host> [--update]" >&2
  echo "  e.g. $0 powehi" >&2
  echo "       $0 local" >&2
  exit 1
fi

FLAKE_DIR="$HOME/dotfiles"

if [[ $UPDATE -eq 1 ]]; then
  nix flake update --flake "$FLAKE_DIR"
fi

if ! command -v darwin-rebuild &> /dev/null; then
  sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake "$FLAKE_DIR#$HOST" --impure
  exit 0
fi

sudo darwin-rebuild switch --flake "$FLAKE_DIR#$HOST" --impure

echo ""
echo "Done. Open a new terminal to reload your shell."
