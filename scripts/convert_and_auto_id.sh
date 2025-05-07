#!/bin/bash
# convert_and_auto_id.sh
#
# This script converts Draw.io diagrams to SVG/HTML and automatically assigns IDs
# to be used as part of the GitHub Actions workflow.

set -e

# Check if we received arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [--all | <file1.drawio> <file2.drawio> ... | --file-list <list_file>]"
    echo "  --all: Process all .drawio files in the drawio_files directory"
    echo "  --file-list <list_file>: Process files listed in the specified file"
    exit 1
fi

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
DRAWIO_DIR="${BASE_DIR}/drawio_files"
SVG_DIR="${BASE_DIR}/svg_files"
HTML_DIR="${BASE_DIR}/html_files"
TEMP_FILE="/tmp/changed_diagrams_list.txt"

# Create directories if they don't exist
mkdir -p "${SVG_DIR}" "${HTML_DIR}"

# Create an empty temporary file
> "$TEMP_FILE"

# Set up the display for headless Draw.io conversion
setup_display() {
    echo "Setting up virtual display for headless operation..."
    mkdir -p /tmp/.X11-unix
    Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp -ac +extension RANDR +render -noreset &
    XVFB_PID=$!
    export DISPLAY=:99
    sleep 2 # Give Xvfb time to start
    echo "Virtual display is set up on :99"
}

# Clean up function to kill Xvfb on exit
cleanup() {
    echo "Cleaning up..."
    if [ -n "$XVFB_PID" ]; then
        kill $XVFB_PID || true
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Check and fix simple numbered filenames
check_filename_format() {
    local input_file="$1"
    local base_name=$(basename "$input_file" .drawio)
    
    # If the file is just a simple number, run the simple renamer first
    if [[ "$base_name" =~ ^[0-9]+$ ]]; then
        echo "File $input_file has a simple numeric name format"
        echo "Running simple file renamer to standardize naming..."
        "${SCRIPT_DIR}/simple_file_renamer.sh" "$input_file"
        
        # The file path will have changed, return the new path
        local new_path="${DRAWIO_DIR}/0.${base_name}.1. Untitled.drawio"
        if [ -f "$new_path" ]; then
            echo "$new_path"
            return 0
        else
            # If renaming failed, return the original path
            echo "$input_file"
            return 1
        fi
    else
        # No change needed, return the original path
        echo "$input_file"
        return 0
    fi
}

# Convert a single diagram file
convert_diagram() {
    local input_file="$1"
    
    # Check and fix the filename format if needed
    local processed_file=$(check_filename_format "$input_file")
    local base_name=$(basename "$processed_file" .drawio)
    local svg_output="${SVG_DIR}/${base_name}.svg"
    local html_output="${HTML_DIR}/${base_name}.html"
    
    echo "Converting: $processed_file"
    
    # Convert to SVG
    if [ ! -f "$svg_output" ] || [ "$input_file" -nt "$svg_output" ]; then
        echo "  Creating SVG: $svg_output"
        drawio --export --format svg --output "$svg_output" "$input_file"
        if [ $? -ne 0 ]; then
            echo "  Error: Failed to convert to SVG"
            return 1
        fi
    else
        echo "  SVG file already up to date"
    fi
    
    # Convert to HTML
    if [ ! -f "$html_output" ] || [ "$input_file" -nt "$html_output" ]; then
        echo "  Creating HTML: $html_output"
        drawio --export --format html --output "$html_output" "$input_file"
        if [ $? -ne 0 ]; then
            echo "  Error: Failed to convert to HTML"
            return 1
        fi
    else
        echo "  HTML file already up to date"
    fi
    
    # Add the file to our list of changed files
    echo "$input_file" >> "$TEMP_FILE"
    
    return 0
}

# Process files based on command line options
process_files() {
    local total=0
    local success=0
    local failed=0
    
    if [ "$1" == "--all" ]; then
        echo "Processing all .drawio files in $DRAWIO_DIR"
        for file in "$DRAWIO_DIR"/*.drawio; do
            # Skip if no files match the pattern
            [ -e "$file" ] || continue
            
            ((total++))
            if convert_diagram "$file"; then
                ((success++))
            else
                ((failed++))
            fi
        done
    elif [ "$1" == "--file-list" ]; then
        if [ -z "$2" ] || [ ! -f "$2" ]; then
            echo "Error: File list not found or not specified"
            return 1
        fi
        
        echo "Processing files from list: $2"
        while IFS= read -r file || [ -n "$file" ]; do
            # Skip empty lines
            [ -z "$file" ] && continue
            
            # Only process .drawio files
            if [[ "$file" == *.drawio ]]; then
                ((total++))
                if convert_diagram "$file"; then
                    ((success++))
                else
                    ((failed++))
                fi
            fi
        done < "$2"
    else
        # Process individual files provided as arguments
        for file in "$@"; do
            if [ -f "$file" ] && [[ "$file" == *.drawio ]]; then
                ((total++))
                if convert_diagram "$file"; then
                    ((success++))
                else
                    ((failed++))
                fi
            else
                echo "Skipping non-existent or non-drawio file: $file"
            fi
        done
    fi
    
    echo "Conversion Summary:"
    echo "  Total files: $total"
    echo "  Successful: $success"
    echo "  Failed: $failed"
    
    # Return success if all files were converted successfully
    return $((failed > 0))
}

# Main execution

# Setup virtual display for headless operation
setup_display

# Process files based on arguments
process_files "$@"
conversion_result=$?

# Run auto ID assignment if files were converted
if [ -s "$TEMP_FILE" ]; then
    echo "Running auto ID assignment for converted files..."
    "${SCRIPT_DIR}/auto_id_converted_diagrams.sh" --file-list "$TEMP_FILE"
    id_result=$?
    if [ $id_result -ne 0 ]; then
        echo "Warning: Some errors occurred during ID assignment"
    fi
else
    echo "No files were converted, skipping ID assignment"
fi

# Clean up
rm -f "$TEMP_FILE"

exit $conversion_result
