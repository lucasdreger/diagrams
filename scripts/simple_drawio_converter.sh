#!/bin/bash
# Simple Draw.io converter script - focuses on core functionality without complex versioning
# Fixes all the path issues and removes the invalid flags

# Set up virtual display for headless operation
mkdir -p /tmp/.X11-unix
Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp -ac +extension RANDR +render -noreset &
XVFB_PID=$!
export DISPLAY=:99
sleep 2 # Give Xvfb time to start

# Verify Xvfb is running
if ! ps -p $XVFB_PID > /dev/null; then
  echo "⚠️ Xvfb failed to start, trying alternative configuration..."
  xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" echo "Testing Xvfb" || echo "Warning: xvfb-run test failed but continuing"
else
  echo "✅ Xvfb started successfully with PID $XVFB_PID"
fi

# Create a simple converter script
cat > /tmp/convert-drawio.sh << 'EOL'
#!/bin/bash
input_file=$1
output_file=$2
echo "Converting: $input_file to $output_file"

# Try direct command first
if drawio -x -f svg -o "$output_file" "$input_file"; then
  exit 0
fi

# Try with xvfb-run as fallback
xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$output_file" "$input_file"
EOL
chmod +x /tmp/convert-drawio.sh

# Track processed files
> /tmp/processed_files.txt
> /tmp/failed_files.txt

# Find all .drawio files that changed in this commit
git diff --name-only HEAD^ HEAD 2>/dev/null | grep -E "\.drawio$" > /tmp/changed_files.txt || echo "" > /tmp/changed_files.txt
if [ ! -s /tmp/changed_files.txt ]; then
  # If first commit or other issue, get all .drawio files
  git diff-tree --name-only --no-commit-id --root -r HEAD | grep -E "\.drawio$" > /tmp/changed_files.txt || echo "" > /tmp/changed_files.txt
fi

echo "Files to process:"
cat /tmp/changed_files.txt

# Process each changed file
while IFS= read -r file || [ -n "$file" ]; do
  if [ -f "$file" ]; then
    echo "Processing: $file"
    
    # Create output directories
    mkdir -p svg_files html_files
    
    # Get base name
    base=$(basename "$file" .drawio)
    output_svg="svg_files/${base}.svg"
    output_html="html_files/${base}.html"
    
    # Convert to SVG
    echo "Converting to SVG..."
    if /tmp/convert-drawio.sh "$file" "$output_svg"; then
      echo "✅ Successfully converted to SVG: $output_svg"
      
      # Create HTML wrapper
      echo "Creating HTML wrapper..."
      echo '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>'"$base"'</title>
  <style>
    body { margin: 0; padding: 0; }
    svg { max-width: 100%; height: auto; display: block; }
  </style>
</head>
<body>' > "$output_html"
      cat "$output_svg" >> "$output_html"
      echo '</body>
</html>' >> "$output_html"
      
      # Add simple changelog entry
      echo "$(date +"%d.%m.%Y"),$(date +"%H:%M:%S"),$base,$(git log -1 --format="%h" --no-color)" >> html_files/CHANGELOG.csv
      
      echo "$file" >> /tmp/processed_files.txt
    else
      echo "❌ Failed to convert: $file"
      echo "$file" >> /tmp/failed_files.txt
    fi
  else
    echo "⚠️ File not found: $file"
  fi
done < /tmp/changed_files.txt

echo "Process completed."
echo "Successful conversions: $(wc -l < /tmp/processed_files.txt)"
echo "Failed conversions: $(wc -l < /tmp/failed_files.txt)"
