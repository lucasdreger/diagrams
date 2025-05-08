#!/bin/bash
# simple_increment_id.sh
#
# This script adds an incremental ID to Draw.io diagram f# Process all versions of a diagram (drawio, svg, html)
process_all_versions() {
    local drawio_path="$1"
    local base_name=$(basename "$drawio_path" .drawio)
    
    # Skip if file already has ID
    if [[ "$base_name" =~ \(ID\ [0-9]+\)$ ]]; then
        echo "File already has an ID: $drawio_path"
        return 0
    }
    
    # Get the next ID
    local next_id=$(get_next_id)
    
    # Add ID to drawio file
    local new_drawio_name="${base_name} (ID ${next_id}).drawio"
    local new_drawio_path="${DRAWIO_DIR}/${new_drawio_name}"
    
    echo "Renaming drawio file:"
    echo "  From: $drawio_path"
    echo "  To:   $new_drawio_path"
    mv "$drawio_path" "$new_drawio_path"
    
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
    
    echo "✅ Successfully added ID ${next_id} to ${base_name}"
    
    # Add to git if available
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git add "$new_drawio_path" 2>/dev/null || true
        [ -f "$new_svg_path" ] && git add "$new_svg_path" 2>/dev/null || true
        [ -f "$new_html_path" ] && git add "$new_html_path" 2>/dev/null || true
    fi
    
    return 0 Format: filename (ID XXX).drawio where XXX is an auto-incrementing number

# Set up error handling
set -e

# Base directories
DRAWIO_DIR="drawio_files"
SVG_DIR="svg_files"
HTML_DIR="html_files"
ID_COUNTER_FILE="${DRAWIO_DIR}/.id_counter"

# Find the highest existing ID number
get_next_id() {
    local highest_id=0
    
    # Check if we have a stored counter
    if [ -f "$ID_COUNTER_FILE" ]; then
        highest_id=$(cat "$ID_COUNTER_FILE")
        echo "Found counter file with value: $highest_id"
    else
        echo "Counter file not found, scanning existing files..."
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
                    echo "Found higher ID: $id in file: $(basename "$file")"
                fi
            fi
        done
    fi
    
    # Increment for the next ID
    next_id=$((highest_id + 1))
    
    # Store the new counter
    mkdir -p "$(dirname "$ID_COUNTER_FILE")"
    echo "$next_id" > "$ID_COUNTER_FILE"
    echo "Saved next ID counter: $next_id"
    
    # Format with leading zeros (3 digits)
    printf "%03d" $next_id
}

# Add ID to a diagram file
add_id_to_file() {
    local file_path="$1"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found: $file_path"
        return 1
    fi
    
    # Check if file already has an ID
    if [[ "$file_path" =~ \(ID\ [0-9]+\)\.[a-z]+$ ]]; then
        echo "File already has an ID: $file_path"
        return 0
    fi
    
    # Get dir, basename and extension
    local dir_name=$(dirname "$file_path")
    local base_name=$(basename "$file_path")
    local extension="${base_name##*.}"
    local name_without_ext="${base_name%.*}"
    
    # Get the next ID
    local next_id=$(get_next_id)
    
    # New filename with ID
    local new_name="${name_without_ext} (ID ${next_id}).${extension}"
    local new_path="${dir_name}/${new_name}"
    
    echo "Adding ID to file:"
    echo "  From: $file_path"
    echo "  To:   $new_path"
    
    # Rename the file
    mv "$file_path" "$new_path"
    
    # Return the new name for use in other scripts
    echo "$new_path"
}

# Process all versions of a diagram (drawio, svg, html)
process_all_versions() {
    local drawio_path="$1"
    local base_name=$(basename "$drawio_path" .drawio)
    
    # Skip if file already has ID
    if [[ "$base_name" =~ \(ID\ [0-9]+\)$ ]]; then
        echo "File already has an ID: $drawio_path"
        return 0
    fi
    
    # Get the next ID
    local next_id=$(get_next_id)
    
    # Process drawio file
    if [ -f "$drawio_path" ]; then
        local new_drawio_name="${base_name} (ID ${next_id}).drawio"
        local new_drawio_path="${DRAWIO_DIR}/${new_drawio_name}"
        echo "Adding ID to drawio file:"
        echo "  From: $drawio_path"
        echo "  To:   $new_drawio_path"
        mv "$drawio_path" "$new_drawio_path"
    fi
    
    # Process SVG file if it exists
    local svg_path="${SVG_DIR}/${base_name}.svg"
    if [ -f "$svg_path" ]; then
        local new_svg_name="${base_name} (ID ${next_id}).svg"
        local new_svg_path="${SVG_DIR}/${new_svg_name}"
        echo "Adding ID to SVG file:"
        echo "  From: $svg_path"
        echo "  To:   $new_svg_path"
        mv "$svg_path" "$new_svg_path"
    fi
    
    # Process HTML file if it exists
    local html_path="${HTML_DIR}/${base_name}.html"
    if [ -f "$html_path" ]; then
        local new_html_name="${base_name} (ID ${next_id}).html"
        local new_html_path="${HTML_DIR}/${new_html_name}"
        echo "Adding ID to HTML file:"
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
    
    # If git is available, commit the changes
    if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Adding changes to git..."
        git add "${DRAWIO_DIR}/" "${SVG_DIR}/" "${HTML_DIR}/" 2>/dev/null || true
        git commit -m "Added ID ${next_id} to ${base_name}" || echo "No changes to commit"
    fi
    
    echo "Successfully added ID ${next_id} to ${base_name}"
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
            process_all_versions "$file"
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
        process_all_versions "$file"
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
            process_all_versions "$file"
        else
            echo "Error: File not found: $file"
        fi
    done
fi
