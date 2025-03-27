#!/bin/bash

# This script helps to check if HTML files are properly generated
# with diagram content

echo "Checking HTML output files..."

HTML_FILES=$(find ./html_files -name "*.html" | sort)

if [ -z "$HTML_FILES" ]; then
  echo "No HTML files found!"
  exit 1
fi

echo "Found HTML files:"
for file in $HTML_FILES; do
  filesize=$(wc -c < "$file")
  diagram_content=$(grep -c "data:image\|svg\|class=\"mxgraph\"" "$file" || true)
  
  echo "- $file (${filesize} bytes)"
  if [ "$filesize" -lt 1000 ]; then
    echo "  WARNING: File seems too small (${filesize} bytes)"
  fi
  
  if [ "$diagram_content" -eq 0 ]; then
    echo "  ERROR: No diagram content detected!"
  else
    echo "  OK: Diagram content found (${diagram_content} mentions)"
  fi
done

echo ""
echo "To test these files, open them in a web browser."
echo "For example: open html_files/test1.html"

chmod +x "$0"
