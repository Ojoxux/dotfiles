#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
extensions_file="${1:-$config_home/cursor/extensions.txt}"

if [[ ! -f "$extensions_file" ]]; then
  echo "extensions list not found: $extensions_file" >&2
  exit 1
fi

mapfile -t extensions < <(grep -Ev '^[[:space:]]*(#|$)' "$extensions_file")

if [[ ${#extensions[@]} -eq 0 ]]; then
  echo "no extensions configured: $extensions_file"
  exit 0
fi

if ! command -v cursor >/dev/null 2>&1; then
  echo "skip cursor: command not found"
  exit 0
fi

echo "sync extensions for cursor"
for extension in "${extensions[@]}"; do
  cursor --install-extension "$extension" --force >/dev/null
  echo "  installed: $extension"
done
