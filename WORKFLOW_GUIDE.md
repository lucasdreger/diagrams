# Draw.io Workflow Guide

This document explains how our GitHub Actions workflow processes Draw.io files in this repository, including the special handling for filenames with spaces.

## Overview

The `drawio-convert.yml` workflow automatically converts `.drawio` files to SVG and HTML formats when changes are pushed to the repository. It also maintains a changelog of all diagram changes in `html_files/CHANGELOG.csv`.

## Support for Files with Spaces

This workflow fully supports filenames with spaces in them. You can create and modify files like:
- `Marketing Plan 2025.drawio`  
- `System Architecture - Version 2.drawio`
- `Team Diagram - Q3 Review.drawio`

The workflow processes only files that were changed in the current commit, including those with spaces in their names. This ensures that:
1. Only modified diagrams are converted and added to the changelog
2. Files with spaces are handled properly without breaking the processing
3. The changelog accurately reflects just the files that were changed in each commit

## Key Features

1. **Automatic Conversion**: Converts all modified `.drawio` files to SVG and HTML
2. **Changelog Generation**: Records all changes with metadata (author, date, version, etc.)
3. **Version Tracking**: Implements semantic versioning (MAJOR.MINOR) for diagrams
4. **SharePoint Integration**: Uploads the changelog to SharePoint for wider visibility
5. **Special Handling for Filenames with Spaces**: Custom logic to ensure files with spaces are processed correctly

## How Filenames with Spaces are Handled

Files with spaces in their names (e.g., "System Architecture - Version 2.drawio") require special handling in shell scripts. Our workflow uses the following techniques:

1. **Finding Files with Spaces**:
   ```bash
   find drawio_files -name "*.drawio" -type f | grep " " > /tmp/files_with_spaces.txt || true
   ```

2. **Dedicated Processing Function**:
   - All files are processed with a dedicated function that handles spaces properly:
   ```bash
   process_diagram_file() {
     local file_to_process="$1"
     # Processing logic that handles spaces correctly
   }
   ```

3. **Line-by-Line File Reading**:
   ```bash
   while IFS= read -r changed_file || [ -n "$changed_file" ]; do
     process_diagram_file "$changed_file"
   done < /tmp/changed_files.txt
   ```

4. **File Path Storage with Newlines as Separators**:
   - We store paths in temporary files with one path per line
   - This avoids issues with spaces in filenames that break word splitting

5. **Proper Quoting Everywhere**:
   - All variables are properly quoted when used in commands
   - This preserves spaces in filenames throughout the workflow

## Workflow Process

1. **Detect Changed Files**: Identifies which `.drawio` files were modified in the commit
2. **Find Files with Spaces**: Explicitly identifies files with spaces in their names
3. **Process Each File**: 
   - Converts to SVG with `drawio -x -f svg -o "$output_path" "$input_file"`
   - Creates HTML wrapper
   - Determines change type (New/Modified) and version
4. **Update Changelog**: Adds entries for each processed file, including commit hash
5. **Commit Changes**: Commits the generated SVG/HTML files
6. **Upload to SharePoint**: Uploads the changelog with commit hashes to SharePoint

## Resolving Common Issues

1. **File Not Being Converted**: If a file with spaces isn't being converted:
   - Check that it's properly detected in the "Files to process" list in the logs
   - Ensure the direct processing section is running
   - Verify the file path doesn't contain special characters beyond spaces

2. **Missing Changelog Entries**: If a file is converted but not appearing in the changelog:
   - Verify the `FILE_CHANGED` flag is set to true
   - Check for errors in the change type detection
   - Ensure proper escaping of special characters in the CSV entry

## Commit Hash Tracking

Each changelog entry includes a short commit hash for tracking purposes. The commit hash is stored in the "Commit Hash" column of the CHANGELOG.csv file and is also preserved when uploading to SharePoint.

### Using Commit Hashes

You can use the commit hash to track diagram changes or restore previous versions:

1. **View an old version**:
   ```zsh
   # Using the short hash from the changelog
   git show abcd123:path/to/file.drawio
   
   # Or get a complete list of changes for a file
   git log --follow --oneline path/to/file.drawio
   ```

2. **Restore to an earlier version**:
   ```zsh
   # Checkout a specific version using the hash from the changelog
   git checkout abcd123 -- path/to/file.drawio
   
   # Then commit the restored version
   git commit -m "Restored file to version abcd123"
   ```

3. **Compare versions**:
   ```zsh
   # Compare a file between two commit hashes
   git diff abcd123 efgh456 -- path/to/file.drawio
   ```

4. **View full commit details**:
   ```zsh
   # Get complete information about the commit
   git show abcd123
   ```

The short hash format (e.g., "abcd123") is used in the changelog for readability, but contains all the information needed to uniquely identify the commit.

## Version Tracking Logic

- New files start at version 1.0
- Minor changes increment the minor version (e.g., 1.0 → 1.1)
- Major changes (detected via keywords) increment the major version and reset minor (e.g., 1.1 → 2.0)

## Last Updated: May 2, 2025
