#!/usr/bin/env bash
# Launch Operation Storm (play mode) on macOS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

find_godot() {
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  local candidates=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "/Applications/Godot 4.app/Contents/MacOS/Godot"
    "/Applications/Godot4.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot 4.app/Contents/MacOS/Godot"
  )
  local path
  for path in "${candidates[@]}"; do
    if [[ -x "$path" ]]; then
      echo "$path"
      return 0
    fi
  done
  local app
  for app in /Applications/Godot*.app /opt/homebrew/Caskroom/godot/*/Godot.app; do
    if [[ -x "${app}/Contents/MacOS/Godot" ]]; then
      echo "${app}/Contents/MacOS/Godot"
      return 0
    fi
  done
  return 1
}

GODOT="$(find_godot)" || {
  echo "Godot 4 not found."
  echo "Install from https://godotengine.org/download/ or:"
  echo "  brew install --cask godot"
  exit 1
}

echo "Using: $GODOT"

# Fresh clones need an import pass so .godot/ class cache + audio samples exist.
if [[ ! -d "$ROOT/.godot/imported" ]] || [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]]; then
  echo "First-time setup: importing project assets (one-time)..."
  "$GODOT" --headless --editor --import --quit-after 1 --path "$ROOT" >/dev/null 2>&1 \
    || "$GODOT" --headless --editor --quit-after 2 --path "$ROOT" >/dev/null 2>&1 \
    || true
fi

exec "$GODOT" --path "$ROOT"
