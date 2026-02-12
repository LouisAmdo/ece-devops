# Branch Management Instructions

## Objective
Rename the branch "lab04-completed" to "master" and delete all other branches.

## Current Branch Structure
- `copilot/rename-lab-4-to-master` (current PR branch - to be deleted after merge)
- `feature/test-cicd` (to be deleted)
- `lab04-completed` (to be renamed to "master")
- `lab6` (to be deleted)
- `main` (to be deleted)

## Steps to Execute

### 1. Rename lab04-completed to master

```bash
# Checkout the lab04-completed branch locally
git checkout lab04-completed

# Rename the local branch to master
git branch -m master

# Push the renamed branch to remote
git push -u origin master

# Delete the old branch on remote
git push origin --delete lab04-completed
```

### 2. Delete other branches

```bash
# Delete feature/test-cicd
git push origin --delete feature/test-cicd

# Delete lab6
git push origin --delete lab6

# Delete main
git push origin --delete main

# Delete copilot/rename-lab-4-to-master (after this PR is merged)
git push origin --delete copilot/rename-lab-4-to-master
```

### 3. Update default branch in GitHub

After renaming, you need to update the default branch in GitHub repository settings:
1. Go to repository Settings
2. Navigate to Branches section
3. Change the default branch from "main" to "master"
4. Confirm the change

### 4. Clean up local branches (optional)

```bash
# Remove tracking references to deleted remote branches
git fetch --prune

# Delete local branches if they exist
git branch -d feature/test-cicd
git branch -d lab6
git branch -d main
git branch -d copilot/rename-lab-4-to-master
```

## Alternative: Using GitHub CLI (gh)

If you have GitHub CLI installed:

```bash
# This would require GitHub CLI with appropriate permissions
# Note: Branch renaming via gh CLI requires manual steps in the web UI
```

## Important Notes

1. **Backup**: Before executing these commands, ensure you have backups or that all important code is merged
2. **Default Branch**: The GitHub default branch must be changed via the web interface
3. **Protected Branches**: If any branches are protected, you'll need to remove protection first
4. **Open PRs**: Check for any open pull requests targeting the branches to be deleted
5. **Permissions**: You need appropriate permissions to delete and rename branches

## Verification

After completion, verify with:
```bash
git fetch --all
git branch -a
```

You should only see the "master" branch.
