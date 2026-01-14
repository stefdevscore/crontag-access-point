#!/usr/bin/env bash
set -euo pipefail

##############################################
# CONFIG
##############################################
OUTPUT_DIR="docs"
OUTPUT_FILE="$OUTPUT_DIR/REPO_TREE.md"
MAX_DEPTH=8

IGNORES=(
  ".git"
  "node_modules"
  "dist"
  "build"
  "coverage"
  "cache"
  ".cache"
  ".tmp"
  ".npm"
  ".yarn"
  ".env"
  ".env.*"
  "artifacts"
  "types"
  "EXECUTION-PLAN.md"
)

##############################################
# CHECK DEPENDENCIES
##############################################
if ! command -v tree >/dev/null 2>&1; then
  echo "Error: 'tree' is not installed."
  echo "Install it with:"
  echo "  brew install tree"
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: This directory is not a Git repository."
  exit 1
fi

##############################################
# ENSURE OUTPUT DIRECTORY
##############################################
mkdir -p "$OUTPUT_DIR"

##############################################
# BUILD TREE IGNORE PATTERN
##############################################
TREE_IGNORE_PATTERN=$(printf "%s|" "${IGNORES[@]}")
TREE_IGNORE_PATTERN="${TREE_IGNORE_PATTERN%|}"

##############################################
# GENERATE OUTPUT
##############################################
{
  echo "# Repository Tree"
  echo ""
  echo "Generated on: \`$(date -u)\`"
  echo ""
  echo "## Directory Tree (Depth $MAX_DEPTH)"
  echo '```'
  tree -I "$TREE_IGNORE_PATTERN" -L "$MAX_DEPTH" --dirsfirst .
  echo '```'
  echo ""
  echo "## Ignored Paths"
  for p in "${IGNORES[@]}"; do
    echo "- \`$p\`"
  done
  echo ""
} > "$OUTPUT_FILE"

echo "Repository tree written to $OUTPUT_FILE"
