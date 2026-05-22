#!/bin/bash
# MoonBit Highlight — Helix Query Installer (Linux/macOS)
# Run from repo root: bash editors/helix/install-queries.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect Helix runtime directory
if [ -n "$HELIX_RUNTIME" ]; then
  RUNTIME_DIR="$HELIX_RUNTIME"
elif [ -n "$XDG_CONFIG_HOME" ]; then
  RUNTIME_DIR="$XDG_CONFIG_HOME/helix/runtime"
else
  RUNTIME_DIR="$HOME/.config/helix/runtime"
fi

TARGET_DIR="$RUNTIME_DIR/queries/moonbit"

echo "Installing MoonBit queries for Helix..."
echo "  Source: $REPO_ROOT/queries"
echo "  Target: $TARGET_DIR"

mkdir -p "$TARGET_DIR"

cp "$REPO_ROOT/queries/highlights.scm" "$TARGET_DIR/"
cp "$REPO_ROOT/queries/indents.scm"    "$TARGET_DIR/"
cp "$REPO_ROOT/queries/locals.scm"     "$TARGET_DIR/"
cp "$REPO_ROOT/queries/injections.scm" "$TARGET_DIR/"

echo "Done! Run 'hx --grammar fetch && hx --grammar build' to build the parser."
