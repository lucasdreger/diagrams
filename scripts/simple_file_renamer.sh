#!/bin/bash
# simple_file_renamer.sh
#
# A simplified script to rename diagrams that don't match the expected pattern
# This will take files like "25.drawio" and rename them to something like "25.1. Untitled.drawio"

# Set default category for simple numbered files
DEFAULT_CATEGORY="0"
DRAWIO_DIR="drawio_files"
SVG_DIR="svg_files"
HTML_DIR="html_files"

# Check if a filename argument was provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <diagram_file>"
  echo "Example: $0 drawio_files/25.drawio"
  exit 1
fi

# Get the input file path
file_path="$1"
dir_name=$(dirname "$file_path")
base_name=$(basename "$file_path" .drawio)

echo "Processing: $file_path"
echo "Base name: $base_name"

# Check if the file already has the expected format
if [[ "$base_name" =~ ^[0-9]+\.[0-9]+\. ]]; then
  echo "File already has the correct format. No renaming needed."
  exit 0
fi

# Handle a simple number case like "25.drawio"
if [[ "$base_name" =~ ^[0-9]+$ ]]; then
  number=$base_name
  # Add default category and auto-incrementing ID
  new_base="${DEFAULT_CATEGORY}.${number}.1. Untitled"
  
  # Construct new paths
  new_drawio_path="${DRAWIO_DIR}/${new_base}.drawio"
  new_svg_path="${SVG_DIR}/${new_base}.svg"
  new_html_path="${HTML_DIR}/${new_base}.html"
  
  echo "Renaming files to standard format:"
  
  # Rename drawio file
  old_drawio_path="${DRAWIO_DIR}/${base_name}.drawio"
  if [ -f "$old_drawio_path" ]; then
    echo "  DrawIO: $old_drawio_path -> $new_drawio_path"
    mv "$old_drawio_path" "$new_drawio_path"
    git add "$new_drawio_path" 2>/dev/null || true
  fi
  
  # Rename SVG file
  old_svg_path="${SVG_DIR}/${base_name}.svg"
  if [ -f "$old_svg_path" ]; then
    echo "  SVG: $old_svg_path -> $new_svg_path"
    mv "$old_svg_path" "$new_svg_path"
    git add "$new_svg_path" 2>/dev/null || true
  fi
  
  # Rename HTML file
  old_html_path="${HTML_DIR}/${base_name}.html"
  if [ -f "$old_html_path" ]; then
    echo "  HTML: $old_html_path -> $new_html_path"
    mv "$old_html_path" "$new_html_path"
    git add "$new_html_path" 2>/dev/null || true
  fi
  
  # Update changelog if it exists
  changelog="${HTML_DIR}/CHANGELOG.csv"
  if [ -f "$changelog" ]; then
    echo "Updating changelog..."
    current_date=$(date +"%d.%m.%Y")
    current_time=$(date +"%H:%M:%S")
    user=$(git config user.name || echo "Manual Script")
    
    # Add entry to changelog
    echo "${current_date},${current_time},\"${user}\",\"${new_base}\",\"Renamed\",\"${base_name} to ${new_base}\",\"Renamed to standard format\",\"1.0\",\"manual\"" >> "$changelog"
    git add "$changelog" 2>/dev/null || true
  fi
  
  echo "Files renamed successfully to standard format."
  
  # Commit the changes if git is available
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git commit -m "Renamed $base_name to standard format $new_base" || echo "Changes staged for commit"
  fi
  
else
  # For other non-standard cases
  echo "File doesn't match expected pattern and isn't a simple number."
  echo "Please rename it manually to format: Category.Level.ID. Description.drawio"
  echo "Example: 3.1.1. SAP Cloud Simplified.drawio"
  exit 1
fi
