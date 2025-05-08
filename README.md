# Diagrams Repository

This repository contains diagrams created with Draw.io and automatically processes them to:

1. Assign sequential ID numbers to diagram files "(ID XXX)" 
2. Convert .drawio files to SVG and HTML formats
3. Maintain a changelog of all diagram modifications

## Workflow Features

- **Auto ID Assignment**: Automatically adds "(ID XXX)" to new diagram filenames
- **Format Conversion**: Converts .drawio files to SVG and HTML formats
- **Changelog**: Tracks all diagram changes with dates and commit information

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
