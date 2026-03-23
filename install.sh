#!/usr/bin/env bash
# Install claude-sync

set -euo pipefail

INSTALL_DIR="${1:-$HOME/.local/bin}"

echo "Installing claude-sync to $INSTALL_DIR..."

mkdir -p "$INSTALL_DIR"
cp claude-sync "$INSTALL_DIR/claude-sync"
chmod +x "$INSTALL_DIR/claude-sync"

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo ""
    echo "Add to your PATH (add to ~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo ""
echo "Installed! Run: claude-sync init"
