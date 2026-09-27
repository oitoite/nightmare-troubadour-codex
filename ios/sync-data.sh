#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve repo root (parent of ios directory)
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Destination directory
DEST_DIR="$SCRIPT_DIR/Packages/NTCodexCore/Sources/NTCodexCore/Resources"

# Ensure destination exists
mkdir -p "$DEST_DIR"

# Copy the JSON files
echo "Syncing data files from $REPO_ROOT to $DEST_DIR..."

cp "$REPO_ROOT/cards.json" "$DEST_DIR/cards.json"
echo "  ✓ cards.json"

cp "$REPO_ROOT/packs.json" "$DEST_DIR/packs.json"
echo "  ✓ packs.json"

cp "$REPO_ROOT/vocabulary.json" "$DEST_DIR/vocabulary.json"
echo "  ✓ vocabulary.json"

cp "$REPO_ROOT/game-terms.json" "$DEST_DIR/game-terms.json"
echo "  ✓ game-terms.json"

echo "Done!"
