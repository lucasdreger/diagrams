#!/bin/bash

echo "Cleaning up repository structure..."

# Remove incorrect workflow files
if [ -d "./github/workflows" ]; then
  echo "Removing incorrect workflow directory at ./github/workflows"
  rm -rf ./github/workflows
fi

# Check for redundant workflow in diagrams subfolder
if [ -f "./diagrams/.github/workflows/main.yml" ]; then
  echo "Found redundant workflow file in diagrams subfolder"
  
  # Optional: Compare the files to ensure they're identical before removing
  if cmp -s "./.github/workflows/main.yml" "./diagrams/.github/workflows/main.yml"; then
    echo "Files are identical, removing redundant workflow"
    rm "./diagrams/.github/workflows/main.yml"
  else
    echo "Warning: Workflow files differ. Please manually review:"
    echo "  - ./.github/workflows/main.yml"
    echo "  - ./diagrams/.github/workflows/main.yml"
  fi
fi

echo "Cleanup completed."
chmod +x "$0"
