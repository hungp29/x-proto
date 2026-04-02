#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLDER_NAME="$(basename "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
ZIP_FILE="$PARENT_DIR/$FOLDER_NAME.xlsx"
PASSFILE="$SCRIPT_DIR/zippass.txt"

if [ ! -f "$PASSFILE" ]; then
  echo "Error: zippass.txt not found in $SCRIPT_DIR" >&2
  exit 1
fi
PASSWORD=$(tr -d '[:space:]' < "$PASSFILE")

# Parse .gitignore patterns into find -name / -path expressions
PRUNE_EXPR=("-name" ".git")
GITIGNORE="$SCRIPT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip blank lines, comments, and negation patterns
    [[ -z "$line" || "$line" == \#* || "$line" == \!* ]] && continue
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    # Remove leading slash (root-anchored marker) and trailing slash (dir marker)
    line="${line#/}"
    line="${line%/}"
    [[ -z "$line" ]] && continue
    # For patterns with path separators (e.g. charts/**/*.tgz), use the basename portion
    # so it matches at any nesting level. Strip ** segments.
    if [[ "$line" == */* ]]; then
      line="${line##*/}"   # take only the last component
      line="${line/\*\*/\*}"  # replace any remaining ** with *
    fi
    [[ -z "$line" || "$line" == "*" ]] && continue
    [ ${#PRUNE_EXPR[@]} -gt 0 ] && PRUNE_EXPR+=("-o")
    PRUNE_EXPR+=("-name" "$line")
  done < "$GITIGNORE"
fi

cd "$PARENT_DIR"
rm -f "$ZIP_FILE"

if [ ${#PRUNE_EXPR[@]} -gt 0 ]; then
  find "$FOLDER_NAME" \( "${PRUNE_EXPR[@]}" \) -prune -o -type f -print \
    | zip -P "$PASSWORD" "$ZIP_FILE" -@
else
  find "$FOLDER_NAME" -type f | zip -P "$PASSWORD" "$ZIP_FILE" -@
fi

echo "Created: $ZIP_FILE"
