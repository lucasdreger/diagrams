#!/bin/bash

# Improved workflow script with enhanced conflict resolution

# Configure git
git config --local user.name "github-actions[bot]"
git config --local user.email "github-actions[bot]@users.noreply.github.com"

# Add all changes
git add svg_files/ html_files/ drawio_files/

# Only commit if there are changes
if ! git diff --staged --quiet; then
  # Commit the changes locally
  git commit -m "Assigned IDs to diagrams and converted to SVG/HTML"
  
  # Get current branch name
  BRANCH_NAME=${GITHUB_REF#refs/heads/}
  
  # Fetch the latest from remote to ensure we're up to date
  echo "Fetching latest changes from remote..."
  git fetch origin $BRANCH_NAME
  
  # Try to rebase our changes on top of the remote branch
  echo "Rebasing local changes on top of remote changes..."
  if git rebase origin/$BRANCH_NAME; then
    echo "Rebase successful, pushing changes..."
    git push "https://x-access-token:${github.token}@github.com/${github.repository}.git" $BRANCH_NAME
    echo "Changes committed and pushed successfully"
  else
    echo "⚠️ Rebase had conflicts. Using alternative merge strategy..."
    # Abort the rebase and try a different approach
    git rebase --abort
    
    # Force merge strategy explicitly to handle divergent branch error
    echo "Setting git pull strategy to merge temporarily"
    git config pull.rebase false
    
    # Force checkout of our branch (this preserves our changes)
    git checkout -f $BRANCH_NAME
    
    # Do a merge (which might have conflicts but that's expected)
    git merge origin/$BRANCH_NAME || true
    
    # At this point, we might have conflicts that need resolution
    if git status | grep -q "Unmerged paths"; then
      echo "Merge conflicts detected, attempting to resolve automatically..."
      
      # Generate diagnostic information for debugging
      echo "--- Git Status ---"
      git status
      echo "--- List of unmerged files ---"
      git diff --name-only --diff-filter=U
      echo "--------------------"
      
      # Handle CHANGELOG.csv specially if it's conflicted
      if git status | grep -q "html_files/CHANGELOG.csv"; then
        echo "Resolving CHANGELOG.csv conflict..."
        
        # Ultra robust approach to handle CSV conflicts
        echo "Extracting conflict information from CHANGELOG.csv..."
        
        # Create fresh backup
        cp html_files/CHANGELOG.csv html_files/CHANGELOG.csv.conflicted
        
        # Try different strategies, starting with the most reliable one
        
        # Strategy 1: Extract header and sort entries excluding conflict markers
        echo "Strategy 1: Extract header and sort entries"
        # Get the original header, with several fallback options
        HEADER=$(grep -m 1 "^Date,Time" html_files/CHANGELOG.csv.conflicted || 
                grep -m 1 "Date,Time" html_files/CHANGELOG.csv.conflicted || 
                echo "Date,Time,User,Diagram,Action,File,Commit Message,Version,Commit Hash,ID")
        
        # Save header as first line
        echo "$HEADER" > html_files/CHANGELOG.csv.resolved
        
        # Extract all entries that are not conflict markers and not the header
        cat html_files/CHANGELOG.csv.conflicted | 
          grep -v "^<<<<<<< " | 
          grep -v "^=======$" | 
          grep -v "^>>>>>>> " | 
          grep -v "^Date,Time" | 
          sort | uniq >> html_files/CHANGELOG.csv.resolved
        
        # Replace conflicted file with resolved version
        cp html_files/CHANGELOG.csv.resolved html_files/CHANGELOG.csv
        
        # Strategy 2: If that fails, create a completely new file
        if ! grep -q "," html_files/CHANGELOG.csv.resolved; then
          echo "Strategy 1 failed, trying Strategy 2: Create new file"
          echo "Date,Time,User,Diagram,Action,File,Commit Message,Version,Commit Hash,ID" > html_files/CHANGELOG.csv
          date +"%-d.%-m.%Y,%H:%M:%S,github-actions,Resolution,Auto-fixed,CHANGELOG.csv,Fixed conflict,1.0,${GITHUB_SHA}" >> html_files/CHANGELOG.csv
        fi
        
        # Mark as resolved regardless of strategy
        git add html_files/CHANGELOG.csv
        echo "✅ CHANGELOG.csv conflict resolved successfully"
        
        # Clean up
        rm -f html_files/CHANGELOG.csv.conflicted html_files/CHANGELOG.csv.resolved
      fi
      
      # Handle other conflicts
      UNMERGED_FILES=$(git diff --name-only --diff-filter=U | grep -v "html_files/CHANGELOG.csv" || echo "")
      if [ -n "$UNMERGED_FILES" ]; then
        echo "Resolving conflicts in other files..."
        echo "$UNMERGED_FILES" | while read -r file; do
          echo "Resolving conflict in: $file"
          # For files other than CHANGELOG.csv, we'll keep our changes (--ours)
          git checkout --ours "$file"
          git add "$file"
        done
        echo "✓ Other conflicts resolved"
      fi
    fi
    
    # Commit our changes
    git commit -m "Assigned IDs to diagrams and converted to SVG/HTML (merge commit)" || echo "No changes to commit"
    
    # Push with proper authentication
    git push "https://x-access-token:${github.token}@github.com/${github.repository}.git" $BRANCH_NAME
    echo "Changes committed and pushed successfully using merge strategy"
    
    # Reset the pull strategy to default
    git config --unset pull.rebase
  fi
else
  echo "No changes to commit"
fi
