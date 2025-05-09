# Diagrams Repository

This repository contains diagrams created with Draw.io and automatically processes them to:

1. Assign sequential ID numbers to diagram files using the X.Y.Z format
2. Convert .drawio files to SVG and HTML formats
3. Maintain a changelog of all diagram modifications

## Recent Fixes

The GitHub Actions workflows have been updated to fix the following issues:

1. **Duplicate Authorization Headers**: Fixed the issue where git commands were failing due to duplicate authorization headers by standardizing the authentication method across all workflows.
   - Removed `git config --local --add http.https://github.com/.extraheader` configurations
   - Standardized to use `git push "https://x-access-token:${{ github.token }}@github.com/${{ github.repository }}.git"` for all git push operations

2. **CHANGELOG.csv Conflict Resolution**: Implemented a robust system to resolve merge conflicts in the CHANGELOG.csv file automatically.
   - Added intelligent conflict marker handling to extract and combine entries from both versions
   - Implemented proper sorting and deduplication of changelog entries
   - Added cleanup of temporary files used in conflict resolution

3. **Enhanced CHANGELOG.csv Conflict Resolution**: Further improved the conflict resolution process to be more reliable.
   - Simplified the resolution approach to avoid using multiple temporary files
   - Added direct header detection and preservation
   - Improved handling of merge conflicts by using a more straightforward approach
   - Fixed issues with conflicted files by directly manipulating the content rather than relying on git commands

4. **Divergent Branches Fix**: Added explicit handling for the divergent branches error that was causing workflow failures.
   - Added explicit `git config pull.rebase false` settings during merge operations
   - Implemented proper cleanup by unsetting temporary git configurations
   - Added diagnostic reporting for merge conflicts
   - Created test scripts to verify conflict resolution strategies

5. **Multi-strategy Conflict Resolution**: Implemented a fallback strategy system for CHANGELOG.csv conflicts.
   - Primary strategy extracts and deduplicates entries from conflicted files
   - Secondary strategy creates a fresh CHANGELOG.csv if extraction fails
   - Improved handling of complex merge scenarios
   - Added better error handling and reporting

6. **Merge Strategy Improvements**:
   - Replaced stash/unstash pattern with a more reliable direct merge approach
   
7. **ID in CHANGELOG.csv**:
   - Added automatic inclusion of diagram ID numbers in the CHANGELOG.csv entries
   - Modified workflow to extract ID from filename when creating changelog entries
   - Added "New" vs "Modified (Update)" action detection for every file
   - Added ID column consistently to all CHANGELOG.csv header definitions
   - Enhanced conflict resolution to preserve IDs during merges
   - Improved conflict resolution for non-CHANGELOG files
   - Implemented better fallback mechanisms when rebasing fails
   - Added retry logic for git push operations

8. **Improved Modify/Delete Conflict Resolution**:
   - Added intelligent handling of modify/delete conflicts for renamed files
   - Added detection for files renamed with ID pattern (e.g., `file.drawio` → `file (ID 001).drawio`)
   - Implemented smart resolution strategy based on file rename detection
   - Fixed the error when deleted files in our branch cannot be checked out with `--ours`
   - Added robust fallback for handling conflicts in both workflow files
   - Created a test script to verify modify/delete conflict resolution
   - Added verbose logging to track workflow execution

9. **Shell Syntax Error with Parentheses**: Fixed a shell syntax error occurring with file paths containing parentheses in the conflict resolution process.
   - Changed the pattern matching approach from `ls "${file%.*} (ID "*"` to `find . -name "${file%.*} (ID*"`
   - This resolves issues when handling files renamed with ID pattern containing parentheses
   - The fix was applied to all workflow files and test scripts
   - For detailed information, see [Shell Syntax Error Fix documentation](docs/SHELL_SYNTAX_ERROR_FIX.md)

10. **Ubuntu 24.04 (Noble) Compatibility**: Fixed package compatibility issues for workflows running on Ubuntu 24.04 (Noble).
   - Updated audio library dependency from `libasound2` to `libasound2t64` for Ubuntu Noble
   - Added version detection to maintain compatibility with older Ubuntu versions
   - Applied the fix to all workflow files to ensure consistency
   - For detailed information, see [Package Compatibility Fix documentation](docs/PACKAGE_COMPATIBILITY_FIX.md)

## Workflow Features

- **Auto ID Assignment**: Automatically adds ID numbers to diagram filenames
- **Format Conversion**: Converts .drawio files to SVG and HTML formats
- **Changelog**: Tracks all diagram changes with dates and commit information
- **Conflict Resolution**: Automatically resolves merge conflicts

## Using This Repository

### Adding New Diagrams

1. Create your diagram with Draw.io and save it in the `drawio_files` directory
2. Commit and push your changes
3. GitHub Actions will automatically:
   - Add an ID to your diagram filename
   - Convert it to SVG and HTML formats
   - Add entries to the changelog

### Modifying Existing Diagrams

Just edit and commit your changes - the workflow will handle the conversion and changelog updates.

## GitHub Actions Workflows

This repository uses GitHub Actions to automatically process diagram files:

- `simple-drawio-workflow.yml`: Main workflow for simple ID assignment and conversion
- `drawio-convert.yml`: Advanced workflow with additional features

## Troubleshooting

If you encounter any issues with the GitHub Actions workflow, check:

1. If there are conflicts in the git repository
2. That the proper permissions are set for GitHub Actions
3. The workflow logs for specific error messages

## Recent Fixes

The workflow has been improved to handle git conflicts and push rejections by:

1. Fetching latest changes before pushing
2. Using rebase as the primary strategy
3. Falling back to merge strategy when rebase conflicts occur
4. Adding retry logic for failed pushes

These improvements ensure that concurrent changes to the repository won't cause workflow failures.
