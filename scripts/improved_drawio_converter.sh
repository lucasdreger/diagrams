#!/bin/bash
# improved_drawio_converter.sh - A more robust solution for converting .drawio files to SVG
#
# USAGE:
#   ./improved_drawio_converter.sh <input_file.drawio> <output_file.svg>
#
# This script uses multiple methods to convert .drawio files to SVG format,
# with enhanced Xvfb handling for better reliability.

set -e # Exit immediately if a command exits with a non-zero status

# Parse arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file.drawio> <output_file.svg>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
SCRIPTS_DIR="$(dirname "$0")"

# Get base name for display in placeholder SVG if needed
BASE_NAME=$(basename "$INPUT_FILE" .drawio)
echo "Starting conversion of $BASE_NAME"

# Make sure input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: Input file not found: $INPUT_FILE"
  exit 1
fi

# Make sure scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
  SCRIPTS_DIR="./scripts"
fi

# Make sure the xvfb wrapper script exists
if [ ! -f "$SCRIPTS_DIR/xvfb_wrapper.sh" ]; then
  echo "ERROR: xvfb_wrapper.sh not found in $SCRIPTS_DIR"
  # Create it inline if missing
  cat > /tmp/xvfb_wrapper.sh << 'EOF'
#!/bin/bash
# Quick fallback xvfb_wrapper.sh

MAX_ATTEMPTS=3
COMMAND="$@"

# Start Xvfb with specific settings
Xvfb :99 -screen 0 1280x1024x24 &
xvfb_pid=$!

# Give Xvfb time to start
sleep 2

# Export the display for the command
export DISPLAY=:99

# Run the command
$COMMAND
exit_code=$?

# Kill Xvfb
kill $xvfb_pid 2>/dev/null

# Return the exit code from the command
exit $exit_code
EOF
  chmod +x /tmp/xvfb_wrapper.sh
  XVFB_WRAPPER="/tmp/xvfb_wrapper.sh"
else
  XVFB_WRAPPER="$SCRIPTS_DIR/xvfb_wrapper.sh"
  chmod +x "$XVFB_WRAPPER"
fi

# Create a temporary error log
ERROR_LOG="/tmp/drawio_conversion_error_$$.log"
touch "$ERROR_LOG"

# Function to check if output file was created successfully
check_output() {
  if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "✅ Method $1 successful"
    rm -f "$ERROR_LOG"
    return 0
  else
    echo "❌ Method $1 failed"
    return 1
  fi
}

# Method 1: Directly extract SVG from the file (no Xvfb needed)
echo "Trying method 1: Direct SVG extraction"
if [ -f "$SCRIPTS_DIR/extract_svg.sh" ]; then
  bash "$SCRIPTS_DIR/extract_svg.sh" "$INPUT_FILE" "$OUTPUT_FILE" 2>>"$ERROR_LOG"
  check_output 1 && exit 0
else
  # Fallback inline extraction
  echo "Extracting SVG directly from file..."
  grep -o '<svg[^>]*>.*</svg>' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>"$ERROR_LOG"
  check_output 1 && exit 0
fi

# Method 2: Using the xvfb_wrapper with drawio -x command
echo "Trying method 2: drawio -x with xvfb_wrapper"
"$XVFB_WRAPPER" drawio -x -f svg -o "$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"
check_output 2 && exit 0

# Method 3: Try with explicitly running Xvfb first
echo "Trying method 3: starting Xvfb explicitly before running drawio"
# Clean up any stale processes
pkill Xvfb || true
sleep 1

# Try multiple display options
for display_num in 10 20 30 40 50; do
  echo "Trying with display :$display_num"
  # Start Xvfb directly
  Xvfb ":$display_num" -screen 0 1280x1024x24 >"/tmp/xvfb_${display_num}.log" 2>&1 &
  xvfb_pid=$!
  sleep 2
  
  # Check if Xvfb started
  if kill -0 $xvfb_pid 2>/dev/null; then
    echo "Xvfb started on display :$display_num"
    export DISPLAY=":$display_num"
    
    # Run drawio with timeout
    timeout 60s drawio -x -f svg -o "$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"
    
    # Kill Xvfb
    kill $xvfb_pid 2>/dev/null
    
    # Check if it worked
    check_output 3 && exit 0
  fi
  # Kill any leftover Xvfb process just to be safe
  kill $xvfb_pid 2>/dev/null || true
done

# Method 4: Using the xvfb_wrapper with drawio --export parameter
echo "Trying method 4: drawio --export with xvfb_wrapper"
"$XVFB_WRAPPER" drawio --export --format svg --output="$OUTPUT_FILE" "$INPUT_FILE" 2>>"$ERROR_LOG"
check_output 4 && exit 0

# Method 4: Try with a headless browser approach if available
if command -v node >/dev/null 2>&1; then
  echo "Trying method 4: Node.js with Puppeteer (if available)"
  
  # Create a temporary Node.js script to convert using Puppeteer
  cat > /tmp/drawio_puppeteer_converter.js << 'EOF'
const fs = require('fs');
const puppeteer = require('puppeteer');

const inputFile = process.argv[2];
const outputFile = process.argv[3];

(async () => {
  try {
    // Check if puppeteer is available
    await import('puppeteer').catch(() => {
      console.error('Puppeteer not available, skipping...');
      process.exit(1);
    });
    
    const content = fs.readFileSync(inputFile, 'utf8');
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    
    // Use diagrams.net in headless mode
    await page.goto('https://app.diagrams.net/?embed=1&ui=min');
    await page.waitForSelector('#graph');
    
    // Import the diagram
    await page.evaluate((content) => {
      window.openFile = function(data) {
        const doc = mxUtils.parseXml(data);
        const codec = new mxCodec(doc);
        const model = new mxGraphModel();
        codec.decode(doc.documentElement.firstChild, model);
        const children = model.getChildCells(model.getRoot());
        graph.getModel().beginUpdate();
        try {
          graph.getModel().setRoot(model.getRoot());
        } finally {
          graph.getModel().endUpdate();
        }
      };
      openFile(content);
    }, content);
    
    // Export as SVG
    const svgData = await page.evaluate(() => {
      return Editor.createSvgDataUri(graph, null, 1);
    });
    
    // Save the SVG file
    const svgContent = svgData.substring('data:image/svg+xml;base64,'.length);
    fs.writeFileSync(outputFile, Buffer.from(svgContent, 'base64').toString('utf8'));
    
    await browser.close();
    console.log('Successfully converted with Puppeteer');
  } catch (err) {
    console.error('Error converting with Puppeteer:', err);
    process.exit(1);
  }
})();
EOF
  
  # Try to run the script if Node.js is available
  node /tmp/drawio_puppeteer_converter.js "$INPUT_FILE" "$OUTPUT_FILE" 2>>"$ERROR_LOG" || echo "Puppeteer method failed or not available"
  check_output 4 && exit 0
fi

# Method 5: Try xmllint if available
if command -v xmllint >/dev/null 2>&1; then
  echo "Trying method 5: xmllint extraction"
  xmllint --xpath '//svg' "$INPUT_FILE" > "$OUTPUT_FILE" 2>>"$ERROR_LOG"
  check_output 5 && exit 0
fi

# All methods failed, create a fallback SVG
echo "All conversion methods failed for $INPUT_FILE"
echo "File info:"
ls -la "$INPUT_FILE"
echo "Content preview:"
head -c 200 "$INPUT_FILE" | hexdump -C
echo "Error log:"
cat "$ERROR_LOG"

# Use create_fallback_svg.sh if available, otherwise create inline
if [ -f "$SCRIPTS_DIR/create_fallback_svg.sh" ]; then
  echo "Creating fallback SVG using create_fallback_svg.sh..."
  bash "$SCRIPTS_DIR/create_fallback_svg.sh" "$OUTPUT_FILE" "$BASE_NAME"
else
  echo "Creating inline fallback SVG..."
  # Create a fallback SVG directly
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
fi

echo "Created fallback SVG to allow workflow to continue"
rm -f "$ERROR_LOG"
exit 1
