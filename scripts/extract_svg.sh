#!/bin/bash
# extract_svg.sh - Extract SVG content from drawio files
#
# Usage: ./extract_svg.sh input_file.drawio output.svg

if [ -f "$1" ]; then
  # Try to find an SVG element in the file
  grep -o '<svg[^>]*>.*</svg>' "$1" > "$2" 2>/dev/null
  
  # Check if extraction worked
  if [ -s "$2" ]; then
    exit 0
  fi
  
  # If not, try a different approach with xmllint if available
  if command -v xmllint >/dev/null 2>&1; then
    xmllint --xpath '//svg' "$1" > "$2" 2>/dev/null
    if [ -s "$2" ]; then
      exit 0
    fi
  fi
  
  exit 1
else
  exit 1
fi
