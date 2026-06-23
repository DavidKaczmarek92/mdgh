#!/usr/bin/env bash
#
# uninstall.sh — Remove mdgh from your system.
#
# Finds where mdgh is installed and deletes it.
#
set -euo pipefail

SCRIPT_NAME="mdgh"

# ─────────────────────────────────────────────────────────────
# Find where mdgh is currently installed.
# ─────────────────────────────────────────────────────────────

current_path="$(command -v "$SCRIPT_NAME" 2>/dev/null || true)"

if [[ -z "$current_path" ]]; then
  echo "✗ $SCRIPT_NAME is not currently installed (not found on PATH)."
  exit 0
fi

echo "→ Found $SCRIPT_NAME at: $current_path"

# ─────────────────────────────────────────────────────────────
# Remove the binary.
# ─────────────────────────────────────────────────────────────

install_dir="$(dirname "$current_path")"

if [[ -w "$current_path" ]]; then
  rm "$current_path"
else
  echo "  (needs admin password to remove from $install_dir)"
  sudo rm "$current_path"
fi

echo "✓ Removed $SCRIPT_NAME binary."

# ─────────────────────────────────────────────────────────────
# Inform about PATH changes.
# ─────────────────────────────────────────────────────────────

shell_rc=""
case "$SHELL" in
  */zsh)  shell_rc="$HOME/.zshrc" ;;
  */bash) shell_rc="$HOME/.bash_profile" ;;
  *)      shell_rc="$HOME/.profile" ;;
esac

if [[ -f "$shell_rc" ]] && grep -q "# Added by mdgh installer" "$shell_rc"; then
  echo ""
  echo "Note: A PATH entry was found in $shell_rc."
  echo "To completely clean up, you may want to manually remove these lines:"
  echo ""
  grep -A 1 "# Added by mdgh installer" "$shell_rc"
fi

echo ""
echo "Successfully uninstalled $SCRIPT_NAME."
