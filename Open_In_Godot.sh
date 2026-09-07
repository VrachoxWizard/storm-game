#!/usr/bin/env bash
# Open Operation Storm in the Godot editor on macOS.
# Works with:  bash Open_In_Godot.sh   OR   ./Open_In_Godot.sh  (after chmod +x)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "$ROOT"

die() {
  echo "" >&2
  echo "ERROR: $*" >&2
  echo "" >&2
  echo "Install Godot 4 (standard, not .NET) from:" >&2
  echo "  https://godotengine.org/download/" >&2
  echo "Or:  brew install --cask godot" >&2
  echo "" >&2
  echo "Then run:  bash Open_In_Godot.sh" >&2
  echo "Optional override:  GODOT_BIN=/path/to/Godot bash Open_In_Godot.sh" >&2
  if [[ -t 0 ]]; then
    read -r -p "Press Enter to close..." _
  fi
  exit 1
}

find_godot() {
  local candidate path app bin brew_prefix
  local apps=()

  if [[ -n "${GODOT_BIN:-}" && -e "${GODOT_BIN}" ]]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi

  for candidate in godot godot4; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  local candidates=(
    "/Applications/Godot.app/Contents/MacOS/Godot"
    "/Applications/Godot 4.app/Contents/MacOS/Godot"
    "/Applications/Godot4.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot"
    "$HOME/Applications/Godot 4.app/Contents/MacOS/Godot"
  )
  for path in "${candidates[@]}"; do
    if [[ -f "$path" || -L "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  shopt -s nullglob
  apps=(
    /Applications/Godot*.app
    "$HOME"/Applications/Godot*.app
    /opt/homebrew/Caskroom/godot/*/Godot.app
    /usr/local/Caskroom/godot/*/Godot.app
  )
  if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "${brew_prefix}" ]]; then
      apps+=("${brew_prefix}"/Caskroom/godot/*/Godot.app)
      apps+=("${brew_prefix}"/Caskroom/godot-mono/*/Godot_mono.app)
    fi
  fi
  shopt -u nullglob

  for app in "${apps[@]+"${apps[@]}"}"; do
    bin="${app}/Contents/MacOS/Godot"
    if [[ -f "$bin" || -L "$bin" ]]; then
      printf '%s\n' "$bin"
      return 0
    fi
    if [[ -d "${app}/Contents/MacOS" ]]; then
      shopt -s nullglob
      for bin in "${app}/Contents/MacOS"/*; do
        if [[ -f "$bin" || -L "$bin" ]]; then
          shopt -u nullglob
          printf '%s\n' "$bin"
          return 0
        fi
      done
      shopt -u nullglob
    fi
  done

  if command -v mdfind >/dev/null 2>&1; then
    while IFS= read -r app; do
      [[ -z "$app" ]] && continue
      bin="${app}/Contents/MacOS/Godot"
      if [[ -f "$bin" || -L "$bin" ]]; then
        printf '%s\n' "$bin"
        return 0
      fi
    done < <(mdfind "kMDItemCFBundleIdentifier == 'org.godotengine.godot'" 2>/dev/null | head -n 8)
  fi

  return 1
}

prepare_godot() {
  local bin="$1"
  local app_bundle

  if [[ -f "$bin" && ! -x "$bin" ]]; then
    chmod +x "$bin" 2>/dev/null || true
  fi

  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$bin" 2>/dev/null || true
    case "$bin" in
      *.app/Contents/MacOS/*)
        app_bundle="${bin%%/Contents/MacOS/*}"
        xattr -dr com.apple.quarantine "$app_bundle" 2>/dev/null || true
        ;;
    esac
  fi
}

GODOT="$(find_godot)" || die "Godot 4 not found on this Mac."
prepare_godot "$GODOT"

if [[ ! -e "$GODOT" ]]; then
  die "Godot path does not exist: $GODOT"
fi

echo "Opening Operation Storm in Godot editor..."
echo "Using: $GODOT"
exec "$GODOT" -e --path "$ROOT"
