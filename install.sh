#!/usr/bin/env bash
#
# install.sh — Install mdgh onto your PATH.
#
# Works on Intel Macs, Apple Silicon Macs (M1/M2/M3...), and Linux.
# No Rust, no compiling, nothing fancy — it just copies one bash
# script to a folder your shell already searches, the same way
# `gh`, `git`, and every other CLI tool ends up runnable by name.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
set -euo pipefail

VERSION="1.0.0"

echo "→ mdgh installer v$VERSION"

SCRIPT_NAME="mdgh"
UPDATE_NAME="mdgh-update"
UNINSTALL_NAME="mdgh-uninstall"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_MAIN="$BASE_DIR/md-to-issues.sh"
SOURCE_UPDATE="$BASE_DIR/update.sh"
SOURCE_UNINSTALL="$BASE_DIR/uninstall.sh"

for f in "$SOURCE_MAIN" "$SOURCE_UPDATE" "$SOURCE_UNINSTALL"; do
  if [[ ! -f "$f" ]]; then
    echo "✗ Could not find $(basename "$f") next to this installer."
    exit 1
  fi
done

# ─────────────────────────────────────────────────────────────
# Pick an install location.
#
# Preference order:
#   1. /opt/homebrew/bin   — Apple Silicon Macs with Homebrew, already on PATH
#   2. /usr/local/bin      — Intel Macs / Linux, already on PATH (needs sudo)
#   3. ~/bin               — no sudo needed, works everywhere, but we have
#                             to add it to PATH ourselves if it's missing
# ─────────────────────────────────────────────────────────────

install_dir=""
needs_sudo=false

if [[ -d "/opt/homebrew/bin" ]] && [[ ":$PATH:" == *":/opt/homebrew/bin:"* ]]; then
  install_dir="/opt/homebrew/bin"
elif [[ -d "/usr/local/bin" ]] && [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
  install_dir="/usr/local/bin"
  [[ -w "$install_dir" ]] || needs_sudo=true
else
  install_dir="$HOME/bin"
fi

echo "→ Installing to: $install_dir"

mkdir -p "$install_dir"

install_file() {
  local src="$1"
  local dst="$2"
  if $needs_sudo; then
    sudo cp "$src" "$dst"
    sudo chmod +x "$dst"
  else
    cp "$src" "$dst"
    chmod +x "$dst"
  fi
}

install_file "$SOURCE_MAIN" "$install_dir/$SCRIPT_NAME"
install_file "$SOURCE_UPDATE" "$install_dir/$UPDATE_NAME"
install_file "$SOURCE_UNINSTALL" "$install_dir/$UNINSTALL_NAME"

echo "✓ Installed $SCRIPT_NAME, $UPDATE_NAME, and $UNINSTALL_NAME."

# ─────────────────────────────────────────────────────────────
# Make sure the install dir is actually on PATH.
# Only relevant for the ~/bin fallback — the other two are
# standard locations already on PATH by default.
# ─────────────────────────────────────────────────────────────

if [[ ":$PATH:" != *":$install_dir:"* ]]; then
  shell_rc=""
  case "$SHELL" in
    */zsh)  shell_rc="$HOME/.zshrc" ;;
    */bash) shell_rc="$HOME/.bash_profile" ;;
    *)      shell_rc="$HOME/.profile" ;;
  esac

  echo "→ Adding $install_dir to PATH in $shell_rc"
  {
    echo ""
    echo "# Added by mdgh installer"
    echo "export PATH=\"$install_dir:\$PATH\""
  } >> "$shell_rc"

  echo "✓ Updated $shell_rc"
  echo ""
  echo "Run this to pick up the change in your current terminal:"
  echo "  source $shell_rc"
  echo ""
  echo "New terminals will pick it up automatically."
else
  echo "✓ $install_dir is already on your PATH."
fi

echo ""
echo "Done. Open a new terminal (or run the 'source' command above) and try:"
echo "  $SCRIPT_NAME --help"