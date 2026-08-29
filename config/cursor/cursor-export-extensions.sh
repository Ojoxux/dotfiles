#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
output_file="${1:-$config_home/cursor/extensions.txt}"
source_dir="${2:-$HOME/.cursor/extensions}"

if [[ ! -d "$source_dir" ]]; then
  echo "cursor extensions directory not found: $source_dir" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_file")"

find "$source_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
  | sed -E 's/-[0-9].*$//' \
  | sort -u > "$output_file"

count=$(wc -l < "$output_file" | tr -d ' ')
echo "exported $count extensions to $output_file"
