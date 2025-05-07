#!/bin/bash

# complete_drawio_converter.sh - A comprehensive solution for converting .drawio files to SVG with multiple fallback methods
# 
# USAGE:
#   ./complete_drawio_converter.sh <input_file.drawio> <output_file.svg>
#
# This script uses multiple methods to convert .drawio files to SVG format:
# 1. Traditional convert-drawio.sh script with xvfb
# 2. Direct drawio -x command
# 3. Modified display settings
# 4. Direct --export parameter
# 5. XML extraction
# 6. Fallback to a well-formatted placeholder SVG

# Parse arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file.drawio> <output_file.svg>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Get base name for display in placeholder SVG if needed
BASE_NAME=$(basename "$INPUT_FILE" .drawio)
echo "Starting conversion of $BASE_NAME"

# Make sure input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# Create a temporary error log
ERROR_LOG="/tmp/drawio_conversion_error_$$.log"
touch "$ERROR_LOG"

# Method 1: Traditional convert-drawio.sh script with xvfb
if [ -f "/tmp/convert-drawio.sh" ]; then
  echo "Trying conversion method 1: convert-drawio.sh script"
  timeout 90s xvfb-run --server-args="-screen 0 1280x1024x24" /tmp/convert-drawio.sh "$INPUT_FILE" "$OUTPUT_FILE" 2>>"$ERROR_LOG"
  
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method 1 successful"
    rm -f "$ERROR_LOG"
    exit 0
  fi
  echo "❌ Method 1 failed"
else
  echo "⚠️ convert-drawio.sh not found, skipping method 1"
fi

# Method 2: Direct drawio -x command
echo "Trying conversion method 2: drawio command with -x flag"
timeout 90s xvfb-run --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ Method 2 successful"
  rm -f "$ERROR_LOG"
  exit 0
fi
echo "❌ Method 2 failed"

# Method 3: Modified display settings
echo "Trying conversion method 3: modified display settings"
export DISPLAY=:0
timeout 60s xvfb-run --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ Method 3 successful"
  rm -f "$ERROR_LOG"
  exit 0
fi
echo "❌ Method 3 failed"

# Method 4: Direct --export parameter
echo "Trying conversion method 4: --export parameter"
timeout 60s xvfb-run --server-args="-screen 0 1280x1024x24" drawio --export --format svg --output="$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ Method 4 successful"
  rm -f "$ERROR_LOG"
  exit 0
fi
echo "❌ Method 4 failed"

# Method 5: XML extraction fallback
echo "Trying conversion method 5: XML extraction"
grep -o '<svg[^>]*>.*</svg>' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>"$ERROR_LOG"

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ Method 5 successful"
  rm -f "$ERROR_LOG"
  exit 0
fi
echo "❌ Method 5 failed"

# If xmllint is available, try it as method 6
if command -v xmllint >/dev/null 2>&1; then
  echo "Trying conversion method 6: xmllint extraction"
  xmllint --xpath '//svg' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>"$ERROR_LOG"
  
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method 6 successful"
    rm -f "$ERROR_LOG"
    exit 0
  fi
  echo "❌ Method 6 failed"
fi

# All methods failed, create a fallback SVG
echo "All conversion methods failed for $INPUT_FILE"
echo "File info:"
ls -la "$INPUT_FILE"
echo "Content preview:"
head -c 200 "$INPUT_FILE" | hexdump -C
echo "Error log:"
cat "$ERROR_LOG"

# Create a fallback SVG - using direct echo instead of heredoc for better compatibility
echo '<?xml version="1.0" encoding="UTF-8"?>' > "$OUTPUT_FILE"
echo '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">' >> "$OUTPUT_FILE"
echo '  <defs>' >> "$OUTPUT_FILE"
echo '    <linearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">' >> "$OUTPUT_FILE"
echo '      <stop offset="0%" style="stop-color:#f8f9fa;stop-opacity:1" />' >> "$OUTPUT_FILE"
echo '      <stop offset="100%" style="stop-color:#e9ecef;stop-opacity:1" />' >> "$OUTPUT_FILE"
echo '    </linearGradient>' >> "$OUTPUT_FILE"
echo '  </defs>' >> "$OUTPUT_FILE"
echo '  <rect width="100%" height="100%" fill="url(#grad)" stroke="#dee2e6" stroke-width="2" />' >> "$OUTPUT_FILE"
echo '  <rect x="20" y="20" width="760" height="560" rx="10" ry="10" fill="white" stroke="#adb5bd" stroke-width="1" />' >> "$OUTPUT_FILE"
echo "  <text x=\"400\" y=\"280\" font-family=\"Arial\" font-size=\"24\" text-anchor=\"middle\" fill=\"#495057\">Diagram: $BASE_NAME</text>" >> "$OUTPUT_FILE"
echo '  <text x="400" y="320" font-family="Arial" font-size="16" text-anchor="middle" fill="#6c757d">This diagram could not be converted to SVG.</text>' >> "$OUTPUT_FILE"
echo '  <text x="400" y="350" font-family="Arial" font-size="14" text-anchor="middle" fill="#6c757d">Please open the original .drawio file to view or edit.</text>' >> "$OUTPUT_FILE"
echo '</svg>' >> "$OUTPUT_FILE"

echo "Created fallback SVG to allow workflow to continue"
rm -f "$ERROR_LOG"
exit 1
