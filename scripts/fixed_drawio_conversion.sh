#!/bin/bash
# Fixed Xvfb setup and drawio conversion script for GitHub Actions

# Set up virtual display for headless operation with improved configuration
# Use standard Xvfb options to avoid XKEYBOARD errors
mkdir -p /tmp/.X11-unix
Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp -ac +extension RANDR +render -noreset &
XVFB_PID=$!
export DISPLAY=:99
sleep 2 # Give Xvfb more time to start

# Verify Xvfb is running
if ! ps -p $XVFB_PID > /dev/null; then
  echo "⚠️ Xvfb failed to start, trying alternative configuration..."
  # Try a different approach with auto-servernum
  xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" echo "Testing Xvfb" || echo "Warning: xvfb-run test failed but continuing"
else
  echo "✅ Xvfb started successfully with PID $XVFB_PID"
fi

# Create an enhanced converter script with better error handling
cat > /tmp/convert-drawio.sh << 'EOL'
#!/bin/bash
input_file=$1
output_file=$2
echo "Starting conversion of $input_file to $output_file"

# First try with direct command
if drawio -x -f svg -o "$output_file" "$input_file"; then
  echo "Conversion successful with direct command"
  exit 0
fi

# Second try with xvfb-run if direct command failed
echo "Trying with xvfb-run..."
if xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$output_file" "$input_file"; then
  echo "Conversion successful with xvfb-run"
  exit 0
fi

# Third try with minimal arguments
echo "Trying with minimal arguments..."
xvfb-run --auto-servernum --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$output_file" "$input_file"
EOL
chmod +x /tmp/convert-drawio.sh

# Create a file to track processed files to avoid duplicates
> /tmp/processed_files.txt

# Function to safely process filenames with spaces
process_diagram_file() {
  local file_to_process="$1"
  echo "===== Processing: $file_to_process ====="
  
  # Check if this file has already been processed
  if grep -q "^$file_to_process\$" /tmp/processed_files.txt; then
    echo "File $file_to_process has already been processed in this run, skipping."
    return 3
  fi
  
  # Skip if file doesn't exist
  if [ ! -f "$file_to_process" ]; then
    echo "File $file_to_process no longer exists, skipping."
    return 1
  fi
  
  # Validation but allow for empty new diagrams
  echo "Validating Draw.io file format..."
  local file_size=$(stat -c%s "$file_to_process" 2>/dev/null || stat -f%z "$file_to_process")
  
  # Check if it contains the basic XML structure
  if ! grep -q "<mxfile" "$file_to_process"; then
    echo "ERROR: $file_to_process is not a valid Draw.io file (missing <mxfile> tag)."
    echo "File content preview:"
    head -c 200 "$file_to_process" | cat -A
    echo ""
    echo "Adding to failed files list..."
    echo "$file_to_process" >> /tmp/failed_files.txt
    echo "Base name: $(basename "$file_to_process" .drawio) - Invalid file format" >> /tmp/failed_files_details.txt
    return 4
  fi
  
  # Small file size warning, but we'll still attempt conversion for new empty diagrams
  if [ "$file_size" -lt 500 ]; then
    echo "NOTE: $file_to_process is very small ($file_size bytes). This is normal for a new empty diagram."
  fi
  
  # Check if this file was actually changed in the current commit
  local was_changed=false
  
  # Method 1: Check changed files list
  grep -q "^$file_to_process\$" /tmp/changed_files.txt && was_changed=true
  
  # Method 2: Direct git diff check (backup if grep fails due to special chars)
  if [ "$was_changed" = false ]; then
    git diff --name-only HEAD^ HEAD 2>/dev/null | grep -q "^$file_to_process\$" && was_changed=true
  fi
  
  # Special case for first commit or files specifically targeted
  if [ ! -s /tmp/changed_files.txt ] || grep -q "^$file_to_process\$" /tmp/files_with_spaces.txt; then
    was_changed=true
  fi
  
  if [ "$was_changed" = false ]; then
    echo "File $file_to_process was not changed in this commit, skipping."
    return 2
  fi
  
  echo "Confirmed $file_to_process was changed in this commit. Processing..."
  
  # Get the base filename without extension, preserving spaces
  local base_name=$(basename "$file_to_process" .drawio)
  echo "Base name: $base_name"
  
  # Create output directories if they don't exist
  mkdir -p "svg_files" "html_files"
  local output_svg="svg_files/${base_name}.svg"
  
  # Check if this is likely a new empty diagram - use more relaxed criteria
  local is_new_empty_diagram=false
  if [ "$file_size" -lt 1000 ]; then
    # First case: Very small file that's definitely a new diagram
    if [ "$file_size" -lt 500 ] && ! grep -q "<mxCell.*value=" "$file_to_process"; then
      echo "This appears to be a new empty diagram (very small size). Will use special handling."
      is_new_empty_diagram=true
    # Second case: Small file that might be empty but has slightly more data
    elif grep -q "<diagram" "$file_to_process" && ! grep -q "<mxCell.*value=" "$file_to_process"; then
      echo "This appears to be an empty or minimal diagram. Will use special handling."
      is_new_empty_diagram=true
    else
      echo "File is small but has content. Will attempt normal conversion."
    fi
  fi
  
  # Convert to SVG with improved error handling
  echo "Converting to SVG..."
  # Create a backup first in case we need to investigate failure
  cp "$file_to_process" "${file_to_process}.backup" 2>/dev/null
  
  if [ "$is_new_empty_diagram" = true ]; then
    # For empty diagrams, create a simple SVG directly
    echo "Creating blank SVG for new empty diagram..."
    # Extract the diagram name from the file for a personalized message
    DIAGRAM_NAME=$(basename "$file_to_process" .drawio)
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
      <rect width="100%" height="100%" fill="white"/>
      <text x="50%" y="45%" font-family="Arial" font-size="20" text-anchor="middle" fill="#333333">'"${DIAGRAM_NAME}"'</text>
      <text x="50%" y="50%" font-family="Arial" font-size="16" text-anchor="middle" fill="#666666">New Diagram - Ready for Editing</text>
      <text x="50%" y="55%" font-family="Arial" font-size="12" text-anchor="middle" fill="#888888">This is an empty diagram template. Open the original .drawio file to edit.</text>
    </svg>' > "$output_svg"
    
    if [ -f "$output_svg" ]; then
      echo "Successfully created SVG for new empty diagram"
    else
      echo "ERROR: Failed to create SVG file for new empty diagram"
      return 1
    fi
  else
    # Prepare the display for conversion
    export DISPLAY=:99
    Xvfb :99 -screen 0 1280x1024x24 > /dev/null 2>&1 &
    sleep 1
                  
    # Standard conversion process for non-empty diagrams
    echo "Trying conversion method 1: convert-drawio.sh script"
    timeout 90s xvfb-run --server-args="-screen 0 1280x1024x24" /tmp/convert-drawio.sh "$file_to_process" "$output_svg" 2>/tmp/conversion_error.log
    
    # Check if conversion succeeded
    if [ ! -f "$output_svg" ] || [ ! -s "$output_svg" ]; then
      echo "First conversion method failed. Trying alternative method..."
      # Method 2: Try the direct drawio command
      echo "Trying conversion method 2: drawio command with -x flag"
      timeout 90s xvfb-run --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$output_svg" "$file_to_process" 2>>/tmp/conversion_error.log
      
      # Method 3: If still failed, try with different display settings
      if [ ! -f "$output_svg" ]; then
        echo "Second conversion method failed. Trying with modified display settings..."
        export DISPLAY=:0
        timeout 60s xvfb-run --server-args="-screen 0 1280x1024x24" drawio -x -f svg -o "$output_svg" "$file_to_process" 2>>/tmp/conversion_error.log
      
        # If all methods failed, record detailed diagnostic info
        if [ ! -f "$output_svg" ]; then
          echo "ERROR: All conversion methods failed for $file_to_process"
          echo "File info:"
          ls -la "$file_to_process"
          echo "Content preview:"
          head -c 200 "$file_to_process" | hexdump -C
          echo "Error log:"
          cat /tmp/conversion_error.log
          
          # Record this failure for notification
          echo "$file_to_process" >> /tmp/failed_files.txt
          echo "Base name: $base_name" >> /tmp/failed_files_details.txt
          
          # Create a minimal valid SVG so the workflow can continue
          echo '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="480" viewBox="0 0 640 480"><rect width="100%" height="100%" fill="#ffffcc"/><text x="10" y="20" font-family="Arial" font-size="16">Error: Failed to convert diagram</text><text x="10" y="45" font-family="Arial" font-size="12">Please check the file and try again</text></svg>' > "$output_svg"
          
          echo "Created placeholder SVG to allow workflow to continue"
          return 1
        fi
      fi
    fi
  fi
  
  echo "Successfully converted to SVG!"
  
  # Create HTML wrapper
  echo "Creating HTML wrapper..."
  local output_html="html_files/${base_name}.html"
  echo '<!DOCTYPE html>' > "$output_html"
  echo '<html lang="en">' >> "$output_html"
  echo '<head>' >> "$output_html"
  echo '  <meta charset="UTF-8">' >> "$output_html"
  echo "  <title>${base_name}</title>" >> "$output_html"
  echo '  <style>' >> "$output_html"
  echo '    body { margin: 0; padding: 0; }' >> "$output_html"
  echo '    svg { max-width: 100%; height: auto; display: block; }' >> "$output_html"
  echo '  </style>' >> "$output_html"
  echo '</head>' >> "$output_html"
  echo '<body>' >> "$output_html"
  cat "$output_svg" >> "$output_html"
  echo '</body>' >> "$output_html"
  echo '</html>' >> "$output_html"
  
  # Get commit information
  local author=$(git log -1 --format="%aN" -- "$file_to_process" 2>/dev/null || echo "GitHub Actions")
  local commit_msg=$(git log -1 --format="%s" -- "$file_to_process" 2>/dev/null || echo "Processing file with spaces")
  local commit_msg_escaped=$(echo "$commit_msg" | sed 's/"/""/g')
  local formatted_date=$(date +"%d.%m.%Y")
  local formatted_time=$(date +"%H:%M:%S")
  local short_hash=$(git log -1 --pretty=format:"%h" -- "$file_to_process" 2>/dev/null || echo "manual")
  
  # Determine if this is new or modified
  local change_type="New"
  local git_history=$(git log --follow --pretty=format:"%h %s" -- "$file_to_process")
  local commit_count=$(echo "$git_history" | wc -l | tr -d ' ')
  
  if [ "$commit_count" -gt 1 ]; then
    change_type="Modified"
    local action_desc="Modified (Update)"
  else
    local action_desc="New"
  fi
  
  # Calculate version
  local version="1.0"
  if [ "$change_type" = "Modified" ]; then
    # Simple calculation: first update is 1.1, and so on
    local minor_version=$((commit_count - 1))
    version="1.${minor_version}"
  fi
  
  # Add changelog entry
  echo "$formatted_date,$formatted_time,\"$author\",\"${base_name}\",\"$action_desc\",\"${base_name}.drawio to ${base_name}.html\",\"$commit_msg_escaped\",\"$version\",\"$short_hash\"" >> html_files/CHANGELOG.csv
  echo "Added entry to changelog for $file_to_process ($action_desc) with version $version"
  
  # Mark this file as processed to avoid duplicates
  echo "$file_to_process" >> /tmp/processed_files.txt
  
  return 0
}

# Set debug output to help troubleshoot
echo "Current directory: $(pwd)"
echo "Listing drawio_files directory:"
ls -la drawio_files || echo "drawio_files directory not found"

# Get the list of changed .drawio files in the current commit
# Use newline separated list to handle spaces in filenames
git diff --name-only HEAD^ HEAD 2>/dev/null | grep -E "\.drawio$" > /tmp/changed_files.txt || echo "" > /tmp/changed_files.txt

# If HEAD^ fails (first commit), try against empty tree
if [ ! -s /tmp/changed_files.txt ]; then
  git diff-tree --name-only --no-commit-id --root -r HEAD | grep -E "\.drawio$" > /tmp/changed_files.txt || echo "" > /tmp/changed_files.txt
fi

echo "Files changed in this commit:"
cat /tmp/changed_files.txt

# Look for changed files with spaces
echo "Checking for changed files with spaces in their names..."

# Create a file to store changed files with spaces
> /tmp/files_with_spaces.txt

# Process each file in changed_files.txt to find those with spaces
if [ -s /tmp/changed_files.txt ]; then
  while IFS= read -r file; do
    if [[ "$file" == *" "* ]]; then
      echo "Found changed file with spaces: $file"
      echo "$file" >> /tmp/files_with_spaces.txt
    fi
  done < /tmp/changed_files.txt
fi

# Process logic for remaining files
# ...
