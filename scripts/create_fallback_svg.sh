#!/bin/bash
# create_fallback_svg.sh - Create a fallback SVG when conversion fails
#
# Usage: ./create_fallback_svg.sh <output_file> <diagram_name>

OUTPUT_FILE="$1"
DIAGRAM_NAME="$2"

# Create a better looking fallback SVG
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
  <text x="400" y="280" font-family="Arial" font-size="24" text-anchor="middle" fill="#495057">Diagram: ${DIAGRAM_NAME}</text>
  <text x="400" y="320" font-family="Arial" font-size="16" text-anchor="middle" fill="#6c757d">This diagram could not be converted to SVG.</text>
  <text x="400" y="350" font-family="Arial" font-size="14" text-anchor="middle" fill="#6c757d">Please open the original .drawio file to view or edit.</text>
</svg>
EOF

echo "Created fallback SVG at $OUTPUT_FILE"
