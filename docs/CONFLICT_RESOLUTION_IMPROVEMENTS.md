# Conflict Resolution Improvements in Diagram Workflows

## Handling Modify/Delete Conflicts for Renamed Files

When diagrams are renamed by adding an ID (e.g., `13.drawio` → `13 (ID 015).drawio`), this creates a special kind of Git conflict called a "modify/delete conflict". This happens when:

1. One branch renames a file (which Git treats as deleting the original and creating a new file)
2. Another branch modifies the original file

When these branches merge, Git sees that one branch deleted a file while the other modified it, creating a conflict.

### Problem Description

Previously, the workflow would fail with errors like:

```
CONFLICT (modify/delete): html_files/13.html deleted in HEAD and modified in origin/main.
error: path 'html_files/13.html' does not have our version
error: path 'svg_files/13.svg' does not have our version
```

This happens because:
- The workflow tried to use `git checkout --ours $file` for all conflicts
- For modify/delete conflicts, this approach fails because our version is the deleted version
- Git can't check out a file that doesn't exist in our version

### Intelligent Conflict Resolution

The improved workflow now handles modify/delete conflicts with a smart strategy:

1. **Detect the conflict type**: Is it a modify/delete conflict?
   ```bash
   if git status | grep -q "deleted by us:.*$file"; then
     # This is a modify/delete conflict where we deleted the file
     # ...
   ```

2. **Check for renamed versions**: Does a renamed version with an ID exist?
   ```bash
   if ls "${file%.*} (ID "*" 2>/dev/null; then
     # Found renamed version with ID
     # ...
   ```

3. **Apply the appropriate strategy**:
   - If a renamed version exists: Accept our deletion of the original, as we've renamed it
   - If no renamed version exists: Keep the remote version to avoid data loss
   - For other conflict types: Use standard conflict resolution

## Benefits

This improved conflict resolution strategy:

1. **Prevents errors** in workflows when diagrams are renamed with IDs
2. **Preserves data integrity** by preventing accidental data loss
3. **Handles edge cases** like concurrent renaming and editing
4. **Reduces manual intervention** needed for resolving conflicts
5. **Makes workflows more robust** against various Git merge scenarios

## Additional Resources

For more information about Git conflict types and resolution strategies:
- [Git Documentation on Merge Conflicts](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging#_basic_merge_conflicts)
- [Understanding Git Conflict Markers](https://wincent.com/wiki/Understanding_Git_conflict_markers)
- [Git Modify/Delete Conflicts](https://stackoverflow.com/questions/4320394/git-resolve-modify-delete-conflict-keeping-the-modified-version)
