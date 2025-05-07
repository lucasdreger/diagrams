#!/bin/bash
# fix_drawio_conversion.sh - Script to fix SVG conversion issues
#
# This script extracts SVG from .drawio files using multiple methods

# Create a temporary directory for our work
mkdir -p /tmp/drawio_conversion

# Usage function
function usage() {
  echo "Usage: $0 <input_drawio_file> <output_svg_file>"
  echo "  <input_drawio_file>: path to the .drawio file to convert"
  echo "  <output_svg_file>: path where the output SVG should be saved"
  exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
  usage
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Input file doesn't exist: $INPUT_FILE"
  exit 1
fi

echo "Starting conversion of $INPUT_FILE to $OUTPUT_FILE"

# Method 1: Try using drawio command with -x flag
echo "Method 1: Using drawio with -x flag"
if command -v drawio &> /dev/null; then
  drawio -x -f svg -o "$OUTPUT_FILE" "$INPUT_FILE" 2>/tmp/drawio_conversion/error.log
  
  # Check if successful
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method 1 successful"
    exit 0
  else
    echo "❌ Method 1 failed"
  fi
else
  echo "⚠️ drawio command not found, skipping method 1"
fi

# Method 2: Try using with export parameter
echo "Method 2: Using drawio with --export parameter"
if command -v drawio &> /dev/null; then
  drawio --export --format svg --output="$OUTPUT_FILE" "$INPUT_FILE" 2>>/tmp/drawio_conversion/error.log
  
  # Check if successful
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method 2 successful"
    exit 0
  else
    echo "❌ Method 2 failed"
  fi
else
  echo "⚠️ drawio command not found, skipping method 2"
fi

# Method 3: XML extraction using grep
echo "Method 3: Extracting SVG using grep"
grep -o '<svg[^>]*>.*</svg>' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>/tmp/drawio_conversion/error.log

# Check if successful
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  echo "✅ Method 3 successful"
  exit 0
else
  echo "❌ Method 3 failed"
fi

# Method 4: Try with xmllint if available
if command -v xmllint &> /dev/null; then
  echo "Method 4: Using xmllint"
  xmllint --xpath '//svg' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>/tmp/drawio_conversion/error.log
  
  # Check if successful
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method 4 successful"
    exit 0
  else
    echo "❌ Method 4 failed"
  fi
else
  echo "⚠️ xmllint not found, skipping method 4"
fi

# If all methods failed, create a fallback SVG
echo "All methods failed. Creating fallback SVG."

# Get the base name for the fallback SVG title
BASE_NAME=$(basename "$INPUT_FILE" .drawio)

# Create a placeholder SVG with nice styling
cat > "$OUTPUT_FILE" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#f8f9fa;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#e9ecef;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="url(#grad)" stroke="#dee2e6" stroke-width="2" />
  <rect x="20" y="20" width="760" height="560" rx="10" ry="10" fill="white" stroke="#adb5bd" stroke-width="1" />
  <text x="400" y="280" font-family="Arial" font-size="24" text-anchor="middle" fill="#495057">Diagram: ${BASE_NAME}</text>
  <text x="400" y="320" font-family="Arial" font-size="16" text-anchor="middle" fill="#6c757d">This diagram could not be converted to SVG.</text>
  <text x="400" y="350" font-family="Arial" font-size="14" text-anchor="middle" fill="#6c757d">Please open the original .drawio file to view or edit.</text>
</svg>
EOF

echo "✅ Created fallback SVG"
echo "⚠️ Conversion was not successful, using fallback SVG"

# Check for errors
if [ -f "/tmp/drawio_conversion/error.log" ]; then
  echo "Error log:"
  cat /tmp/drawio_conversion/error.log
fi

exit 0
