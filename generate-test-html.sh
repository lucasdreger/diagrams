#!/bin/bash

# This script manually converts a .drawio file to HTML for testing

if [ $# -eq 0 ]; then
  echo "Usage: $0 path/to/file.drawio"
  exit 1
fi

INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File not found: $INPUT_FILE"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p html_files

# Generate filename
FILENAME=$(basename "$INPUT_FILE")
OUTPUT_FILE="html_files/${FILENAME%.drawio}.html"

echo "Converting $INPUT_FILE to $OUTPUT_FILE"

# Check if drawio is installed
if ! command -v drawio &> /dev/null; then
  echo "Error: drawio command not found. Please install Draw.io Desktop."
  exit 1
fi

# Convert with improved parameters
drawio -x -f html --embed --tags --tooltips -o "$OUTPUT_FILE" "$INPUT_FILE"

echo "Done! Open the file with: open $OUTPUT_FILE"

chmod +x "$0"
