#!/bin/bash
# ultra_simple_id.sh
#
# The most basic script to add (ID XXX) to diagram filenames

# Configuration
ID_FILE="/Users/lucasdreger/apps/diagrams/drawio_files/.id_counter"

# Ensure we have an initial ID counter
if [ ! -f "$ID_FILE" ]; then
  echo "1" > "$ID_FILE"
  echo "Created new ID counter file"
fi

# Get the current ID and increment it
CURRENT_ID=$(cat "$ID_FILE" 2>/dev/null || echo "1")
echo "Current ID counter is: $CURRENT_ID"

NEXT_ID=$((CURRENT_ID + 1))
echo "Next ID will be: $NEXT_ID"

# Save the next ID for future use
echo "$NEXT_ID" > "$ID_FILE"

# Format the ID with leading zeros
FORMATTED_ID=$(printf "%03d" $CURRENT_ID)
echo "Formatted ID for this file: $FORMATTED_ID"

# File to process
FILE="$1"
if [ ! -f "$FILE" ]; then
  echo "Error: File not found: $FILE"
  exit 1
fi

# Get base name and directory
DIR=$(dirname "$FILE")
BASE=$(basename "$FILE" .drawio)

# Skip if it already has an ID
if [[ "$BASE" =~ \(ID\ [0-9]+\)$ ]]; then
  echo "File already has an ID: $FILE"
  exit 0
fi

# New name with ID added
NEW_NAME="${BASE} (ID ${FORMATTED_ID}).drawio"
NEW_PATH="${DIR}/${NEW_NAME}"

# Do the rename for drawio file
echo "Renaming drawio file:"
echo "  From: $FILE"
echo "  To:   $NEW_PATH"
mv "$FILE" "$NEW_PATH"

# Also rename SVG file if it exists
SVG_PATH="svg_files/${BASE}.svg"
if [ -f "$SVG_PATH" ]; then
  NEW_SVG_NAME="${BASE} (ID ${FORMATTED_ID}).svg"
  NEW_SVG_PATH="svg_files/${NEW_SVG_NAME}"
  echo "Renaming SVG file:"
  echo "  From: $SVG_PATH"
  echo "  To:   $NEW_SVG_PATH"
  mv "$SVG_PATH" "$NEW_SVG_PATH"
  echo "SVG file renamed"
fi

# Also rename HTML file if it exists
HTML_PATH="html_files/${BASE}.html"
if [ -f "$HTML_PATH" ]; then
  NEW_HTML_NAME="${BASE} (ID ${FORMATTED_ID}).html"
  NEW_HTML_PATH="html_files/${NEW_HTML_NAME}"
  echo "Renaming HTML file:"
  echo "  From: $HTML_PATH"
  echo "  To:   $NEW_HTML_PATH"
  mv "$HTML_PATH" "$NEW_HTML_PATH"
  echo "HTML file renamed"
fi

# Check result
if [ -f "$NEW_PATH" ]; then
  echo "Success! File renamed with ID: $FORMATTED_ID"
  
  # Update git if available
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Adding changes to git..."
    git add "$NEW_PATH" 2>/dev/null || true
    [ -f "$NEW_SVG_PATH" ] && git add "$NEW_SVG_PATH" 2>/dev/null || true
    [ -f "$NEW_HTML_PATH" ] && git add "$NEW_HTML_PATH" 2>/dev/null || true
  fi
else
  echo "Error: Failed to rename file"
  exit 1
fi
