#!/bin/bash
# auto_id_converted_diagrams.sh
#
# This script automatically assigns incremental IDs to Draw.io diagrams 
# after they've been converted to SVG and HTML formats.
# It renames all three versions of the file (drawio, svg, html) with the new ID.
#
# The naming convention is:
#   Category.DetailLevel.ID. DiagramName
#   Where:
#   Category - Diagram category (e.g., 1=Cloud, 2=Network, 3=SAP)
#   DetailLevel - Detail level (e.g., 1=Big landscape, 2=Solution undetailed, 3=Solution detailed)
#   ID - Auto-incrementing identifier
#   DiagramName - Description of the diagram

# Set up error handling
set -e

# Base directories
DRAWIO_DIR="drawio_files"
SVG_DIR="svg_files"
HTML_DIR="html_files"
CHANGELOG_FILE="${HTML_DIR}/CHANGELOG.csv"

# Find diagrams matching the pattern and extract the highest ID value
find_highest_id() {
    local category_level="$1"  # e.g., "3.1"
    local highest_id=0
    
    # Look in the drawio_files directory for existing IDs
    if [ -d "$DRAWIO_DIR" ]; then
        for file in "$DRAWIO_DIR"/*.drawio; do
            # Skip if no files match
            [ -e "$file" ] || continue
            
            # Extract the base filename
            base_name=$(basename "$file" .drawio)
            
            # Check if the file matches our pattern with the correct category/level
            if [[ "$base_name" =~ ^${category_level}\.([0-9]+)\. ]]; then
                id_value="${BASH_REMATCH[1]}"
                if (( id_value > highest_id )); then
                    highest_id="$id_value"
                fi
            fi
        done
    fi
    
    echo "$highest_id"
}

# Process and rename all versions of a diagram
process_diagram() {
    local drawio_path="$1"
    
    # Check if the file exists
    if [ ! -f "$drawio_path" ]; then
        echo "Error: File not found: $drawio_path"
        return 1
    }
    
    # Extract base components
    local dir_name=$(dirname "$drawio_path")
    local base_name=$(basename "$drawio_path" .drawio)
    local extension="${drawio_path##*.}"
    
    # Parse the filename and extract the category and level
    if [[ "$base_name" =~ ^([0-9]+\.[0-9]+)\. ]]; then
        local category_level="${BASH_REMATCH[1]}"
        local remainder="${base_name#${category_level}.}"
        
        # Find the highest existing ID for this category/level
        local highest_id=$(find_highest_id "$category_level")
        
        # Calculate the next ID
        local next_id=$((highest_id + 1))
        
        # Generate the new filename
        local new_base_name="${category_level}.${next_id}. ${remainder}"
        local new_drawio_path="${DRAWIO_DIR}/${new_base_name}.drawio"
        local new_svg_path="${SVG_DIR}/${new_base_name}.svg"
        local new_html_path="${HTML_DIR}/${new_base_name}.html"
        
        echo "Processing diagram with ID assignment:"
        echo "  Category/Level: $category_level"
        echo "  New ID: $next_id"
        echo "  Base name: $remainder"
        
        # Check if the corresponding SVG and HTML files exist
        local old_svg_path="${SVG_DIR}/${base_name}.svg"
        local old_html_path="${HTML_DIR}/${base_name}.html"
        
        # Rename the files if they exist
        local commit_message="Auto-assigned ID ${next_id} to ${base_name}"
        local files_renamed=0
        
        # Rename drawio file
        if [ -f "$drawio_path" ]; then
            echo "Renaming drawio file:"
            echo "  From: $drawio_path"
            echo "  To:   $new_drawio_path"
            git mv "$drawio_path" "$new_drawio_path" || mv "$drawio_path" "$new_drawio_path"
            git add "$new_drawio_path"
            ((files_renamed++))
        fi
        
        # Rename SVG file if it exists
        if [ -f "$old_svg_path" ]; then
            echo "Renaming SVG file:"
            echo "  From: $old_svg_path"
            echo "  To:   $new_svg_path"
            git mv "$old_svg_path" "$new_svg_path" || mv "$old_svg_path" "$new_svg_path"
            git add "$new_svg_path"
            ((files_renamed++))
        fi
        
        # Rename HTML file if it exists
        if [ -f "$old_html_path" ]; then
            echo "Renaming HTML file:"
            echo "  From: $old_html_path"
            echo "  To:   $new_html_path"
            git mv "$old_html_path" "$new_html_path" || mv "$old_html_path" "$new_html_path"
            git add "$new_html_path"
            ((files_renamed++))
        fi
        
        # Add entry to changelog if it exists
        if [ -f "$CHANGELOG_FILE" ] && [ $files_renamed -gt 0 ]; then
            echo "Updating changelog..."
            local current_date=$(date +"%d.%m.%Y")
            local current_time=$(date +"%H:%M:%S")
            local user=$(git config user.name || echo "Automated Script")
            local version="1.0"
            local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
            
            # Add new entry to changelog
            echo "${current_date},${current_time},\"${user}\",\"${new_base_name}\",\"Renamed\",\"${base_name} to ${new_base_name}\",\"${commit_message}\",\"${version}\",\"${commit_hash}\"" >> "$CHANGELOG_FILE"
            git add "$CHANGELOG_FILE"
        fi
        
        # Commit the changes if any files were renamed
        if [ $files_renamed -gt 0 ]; then
            git commit -m "$commit_message" || echo "Changes staged for commit"
            echo "Successfully renamed $files_renamed files with next available ID: $next_id"
            echo "Commit message: $commit_message"
        else
            echo "No files were renamed."
        fi
        
        # Return the new base name for use in other scripts
        echo "$new_base_name"
    else
        echo "Error: Filename does not match the expected pattern (e.g., '3.1. SAP Overview')"
        echo "Expected format: Category.DetailLevel. DiagramName"
        echo "Example: 3.1. SAP Overview (would become 3.1.4. SAP Overview with ID 4)"
        return 1
    fi
}

# Process multiple diagrams from a file list
process_multiple_diagrams() {
    local file_list="$1"
    
    if [ ! -f "$file_list" ]; then
        echo "Error: File list not found: $file_list"
        return 1
    fi
    
    local processed_count=0
    local error_count=0
    
    while IFS= read -r file || [ -n "$file" ]; do
        # Skip empty lines
        [ -z "$file" ] && continue
        
        # Only process .drawio files
        if [[ "$file" == *.drawio ]]; then
            echo "========================================="
            echo "Processing diagram: $file"
            if process_diagram "$file"; then
                ((processed_count++))
            else
                ((error_count++))
                echo "Error processing: $file"
            fi
            echo "========================================="
        fi
    done < "$file_list"
    
    echo "Summary:"
    echo "  Processed: $processed_count diagrams"
    echo "  Errors: $error_count diagrams"
    
    return $error_count
}

# Main execution
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <diagram_file_path> [diagram_file_path2 ...]"
    echo "   OR: $0 --file-list <path_to_file_with_list_of_diagrams>"
    echo "Examples:"
    echo "   $0 drawio_files/3.1.\ SAP\ Overview.drawio"
    echo "   $0 --file-list /tmp/changed_files.txt"
    exit 1
fi

# Process arguments
if [ "$1" == "--file-list" ]; then
    if [ -z "$2" ]; then
        echo "Error: No file list provided"
        exit 1
    fi
    process_multiple_diagrams "$2"
else
    # Process each diagram individually
    for diagram in "$@"; do
        process_diagram "$diagram"
    done
fi
