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

SCRIPT_NAME="mdgh"
SOURCE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/md-to-issues.sh"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "✗ Could not find md-to-issues.sh next to this installer."
  echo "  Make sure install.sh and md-to-issues.sh are in the same folder."
  exit 1
fi

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

echo "→ Installing to: $install_dir/$SCRIPT_NAME"

mkdir -p "$install_dir"

if $needs_sudo; then
  echo "  (needs admin password to write to $install_dir)"
  sudo cp "$SOURCE_FILE" "$install_dir/$SCRIPT_NAME"
  sudo chmod +x "$install_dir/$SCRIPT_NAME"
else
  cp "$SOURCE_FILE" "$install_dir/$SCRIPT_NAME"
  chmod +x "$install_dir/$SCRIPT_NAME"
fi

echo "✓ Copied."

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