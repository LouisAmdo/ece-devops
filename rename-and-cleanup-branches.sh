#!/bin/bash

# Script to rename lab04-completed to master and delete other branches
# This script should be run by someone with appropriate GitHub repository permissions

set -e  # Exit on error

echo "Branch Management Script"
echo "======================="
echo ""
echo "This script will:"
echo "1. Rename lab04-completed to master"
echo "2. Delete all other branches"
echo ""
echo "WARNING: This operation cannot be easily undone!"
read -p "Do you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Ensure we're in the repository directory
cd "$(git rev-parse --show-toplevel)"

echo ""
echo "Step 1: Fetching all branches..."
git fetch --all

echo ""
echo "Step 2: Checking out lab04-completed branch..."
git checkout lab04-completed

echo ""
echo "Step 3: Renaming local branch to master..."
git branch -m master

echo ""
echo "Step 4: Pushing renamed branch to remote and setting upstream..."
git push -u origin master

echo ""
echo "Step 5: Deleting old lab04-completed branch from remote..."
git push origin --delete lab04-completed

echo ""
echo "Step 6: Deleting other branches from remote..."
branches_to_delete=("feature/test-cicd" "lab6" "main")

for branch in "${branches_to_delete[@]}"; do
    echo "  Deleting $branch..."
    git push origin --delete "$branch" || echo "  Warning: Could not delete $branch (may not exist or permission denied)"
done

echo ""
echo "Step 7: Cleaning up local tracking references..."
git fetch --prune

echo ""
echo "Step 8: Deleting local branches (if they exist)..."
for branch in "${branches_to_delete[@]}"; do
    git branch -d "$branch" 2>/dev/null || echo "  Local branch $branch not found or already deleted"
done

echo ""
echo "======================================"
echo "Branch management completed!"
echo ""
echo "IMPORTANT: You still need to:"
echo "1. Go to GitHub repository Settings > Branches"
echo "2. Change the default branch to 'master'"
echo "3. Delete the copilot/rename-lab-4-to-master branch after its PR is merged"
echo ""
echo "Current branches:"
git branch -a
