# Manual Regeneration of All Diagrams

## Overview

This guide explains how to use the "Regenerate All Draw.io Exports" workflow to manually regenerate all SVG and HTML files from your existing Draw.io diagrams, even if those diagrams haven't been changed.

## When to Use This Workflow

Use this manual regeneration workflow in scenarios like:

1. Some HTML or SVG files were accidentally deleted
2. You've made changes to the HTML template format and want to update all files
3. The automatic conversion failed for some diagrams and you want to try again
4. After upgrading the Draw.io converter to ensure all diagrams use the latest format

## How to Run It

1. Go to the **Actions** tab in your GitHub repository
2. Select the **Regenerate All Draw.io Exports** workflow from the sidebar
3. Click the **Run workflow** button
4. Configure the options:
   - **Regenerate all diagram exports**: Should be set to `true` (default)
   - **Force processing**: Set to `true` if you want to overwrite existing files, or `false` to skip diagrams that already have SVG/HTML files
5. Click **Run workflow**

## Options Explained

### Regenerate all diagram exports
This option should be set to `true` to process all Draw.io files. This is the default and typically what you want.

### Force processing
- **false** (default): The workflow will skip diagrams that already have corresponding SVG and HTML files, only processing diagrams where exports are missing.
- **true**: The workflow will regenerate SVG and HTML files for all diagrams, overwriting any existing files. Use this when you want to refresh all output files.

## Workflow Behavior

When run, the workflow will:

1. Check out your repository
2. Set up the Draw.io conversion tools
3. Process all `.drawio` files in the `drawio_files` directory:
   - Convert each diagram to SVG
   - Create HTML wrappers with proper formatting
   - Handle empty diagrams appropriately
4. Update the changelog to record the bulk regeneration
5. Commit and push changes to your repository
6. Send a Teams notification with the results

## Status Notifications

The workflow sends Teams notifications with different colors depending on the outcome:

- **Green**: All diagrams were processed successfully
- **Orange**: Some diagrams were processed, but some failed
- **Red**: All diagrams failed to process

Each notification includes:
- Number of files processed
- Number of files that failed
- Whether force mode was enabled
- Who triggered the workflow

## Avoiding Unnecessary Processing

If you don't need to regenerate files for all diagrams, consider using the standard automatic workflow instead, which only processes changed files.

## Troubleshooting

If some diagrams fail to convert:

1. Check the workflow logs for specific error messages
2. Verify that the Draw.io files are valid and not corrupted
3. For persistent issues with specific diagrams, try opening them in Draw.io and saving them again to ensure they use the latest format
4. Run the workflow again with the "Force processing" option enabled
