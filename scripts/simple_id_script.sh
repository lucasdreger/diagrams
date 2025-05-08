#!/bin/bash
# simple_id_script.sh
#
# A very simple script that adds "(ID XXX)" to the end of diagram filenames
# The ID starts from 001 and increments for each new file
# Once a file has an ID, it keeps that ID forever

# Configuration
DRAWIO_DIR="drawio_files"
SVG_DIR="svg_files"
HTML_DIR="html_files"
ID_COUNTER_FILE="${DRAWIO_DIR}/.id_counter"
ID_PATTERN="\(ID [0-9]{3}\)"  # Pattern to match (ID XXX) where X is a digit

# Find the highest existing ID number
get_next_id() {
    local highest_id=0
    
    # Check if we have a stored counter
    if [ -f "$ID_COUNTER_FILE" ]; then
        highest_id=$(cat "$ID_COUNTER_FILE")
        >&2 echo "Found counter file with value: $highest_id"
    else
        >&2 echo "Counter file not found, scanning existing files..."
        # If no counter file exists, scan the directory for the highest ID
        for file in ${DRAWIO_DIR}/*.drawio ${SVG_DIR}/*.svg ${HTML_DIR}/*.html; do
            # Skip if no files match
            [ -e "$file" ] || continue
            
            # Extract ID from filename if present
            if [[ "$file" =~ \(ID\ ([0-9]+)\)\.[a-z]+$ ]]; then
                id=${BASH_REMATCH[1]}
                # Remove leading zeros for comparison
                id=$(echo "$id" | sed 's/^0*//')
                if [ -z "$id" ]; then id=0; fi
                if (( id > highest_id )); then
                    highest_id=$id
                    >&2 echo "Found higher ID: $id in file: $(basename "$file")"
                fi
            fi
        done
    fi
    
    # Increment for the next ID
    next_id=$((highest_id + 1))
    
    # Store the new counter
    mkdir -p "$(dirname "$ID_COUNTER_FILE")"
    echo "$next_id" > "$ID_COUNTER_FILE"
    >&2 echo "Saved next ID counter: $next_id"
    
    # Format with leading zeros (3 digits)
    printf "%03d" $next_id
}

# Process all versions of a diagram (drawio, svg, html)
process_diagram() {
    local drawio_path="$1"
    local base_name=$(basename "$drawio_path" .drawio)
    
    # Skip if file already has ID
    if [[ "$base_name" =~ \(ID\ [0-9]+\)$ ]]; then
        echo "File already has an ID: $drawio_path"
        return 0
    fi
    
    # Get the next ID
    local next_id=$(get_next_id)
    
    # Add ID to drawio file
    local new_drawio_name="${base_name} (ID ${next_id}).drawio"
    local new_drawio_path="$(dirname "$drawio_path")/${new_drawio_name}"
    
    echo "Renaming drawio file:"
    echo "  From: $drawio_path"
    echo "  To:   $new_drawio_path"
    
    # Debug
    echo "Debug: Checking file existence"
    echo "Original file exists: $([ -f "$drawio_path" ] && echo "YES" || echo "NO")"
    echo "Original file size: $([ -f "$drawio_path" ] && wc -c < "$drawio_path" || echo "N/A") bytes"
    
    # Use mv with verbose output
    mv -v "$drawio_path" "$new_drawio_path"
    
    # Verify move
    echo "New file exists: $([ -f "$new_drawio_path" ] && echo "YES" || echo "NO")"
    
    # Also rename SVG file if it exists
    local svg_path="${SVG_DIR}/${base_name}.svg"
    if [ -f "$svg_path" ]; then
        local new_svg_name="${base_name} (ID ${next_id}).svg"
        local new_svg_path="${SVG_DIR}/${new_svg_name}"
        echo "Renaming SVG file:"
        echo "  From: $svg_path"
        echo "  To:   $new_svg_path"
        mv "$svg_path" "$new_svg_path"
    fi
    
    # Also rename HTML file if it exists
    local html_path="${HTML_DIR}/${base_name}.html"
    if [ -f "$html_path" ]; then
        local new_html_name="${base_name} (ID ${next_id}).html"
        local new_html_path="${HTML_DIR}/${new_html_name}"
        echo "Renaming HTML file:"
        echo "  From: $html_path"
        echo "  To:   $new_html_path"
        mv "$html_path" "$new_html_path"
    fi
    
    # Update changelog if it exists
    local changelog="${HTML_DIR}/CHANGELOG.csv"
    if [ -f "$changelog" ]; then
        echo "Updating changelog..."
        local current_date=$(date +"%d.%m.%Y")
        local current_time=$(date +"%H:%M:%S")
        local user=$(git config user.name || echo "Automated Script")
        
        echo "${current_date},${current_time},\"${user}\",\"${base_name} (ID ${next_id})\",\"ID Added\",\"${base_name} → ${base_name} (ID ${next_id})\",\"Added ID ${next_id}\",\"1.0\",\"auto\"" >> "$changelog"
    fi
    
    echo "✅ Successfully added ID ${next_id} to ${base_name}"
    
    # Add to git if available
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git add "$new_drawio_path" 2>/dev/null || true
        [ -f "$new_svg_path" ] && git add "$new_svg_path" 2>/dev/null || true
        [ -f "$new_html_path" ] && git add "$new_html_path" 2>/dev/null || true
        echo "Added changes to git"
    fi
    
    return 0
}

# Process a list of files from a file
process_file_list() {
    local file_list="$1"
    
    if [ ! -f "$file_list" ]; then
        echo "Error: File list not found: $file_list"
        return 1
    fi
    
    local processed=0
    
    while IFS= read -r file || [ -n "$file" ]; do
        # Skip empty lines
        [ -z "$file" ] && continue
        
        # Only process .drawio files
        if [[ "$file" == *.drawio ]]; then
            echo "========================================="
            echo "Processing: $file"
            process_diagram "$file"
            ((processed++))
            echo "========================================="
        fi
    done < "$file_list"
    
    echo "Processed $processed .drawio files from list"
}

# Process all drawio files in the directory
process_all_files() {
    local count=0
    
    echo "Finding all .drawio files without IDs..."
    for file in ${DRAWIO_DIR}/*.drawio; do
        # Skip if no files match
        [ -e "$file" ] || continue
        
        # Skip files that already have IDs
        base_name=$(basename "$file" .drawio)
        if [[ "$base_name" =~ \(ID\ [0-9]+\)$ ]]; then
            echo "Skipping file with ID: $file"
            continue
        fi
        
        echo "========================================="
        echo "Processing: $file"
        process_diagram "$file"
        ((count++))
        echo "========================================="
    done
    
    echo "Added IDs to $count files"
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 [--all | --file-list <list_file> | <file1.drawio> <file2.drawio> ...]"
    echo "  --all: Process all .drawio files in the drawio_files directory"
    echo "  --file-list <list_file>: Process files listed in the specified file"
    echo "  <file.drawio>: Process the specified file(s)"
    exit 1
fi

# Process based on arguments
if [ "$1" == "--all" ]; then
    echo "Processing all .drawio files..."
    process_all_files
elif [ "$1" == "--file-list" ]; then
    if [ -z "$2" ]; then
        echo "Error: No file list provided"
        exit 1
    fi
    echo "Processing files from list: $2"
    process_file_list "$2"
else
    # Process individual files
    for file in "$@"; do
        if [ -f "$file" ]; then
            echo "Processing file: $file"
            process_diagram "$file"
        else
            echo "Error: File not found: $file"
        fi
    done
fi
