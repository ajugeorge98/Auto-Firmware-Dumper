#!/usr/bin/bash

# Import common functions for 'error' and 'Echo'
# Assuming this script is in the same directory as common_functions.sh
[ -f "$(dirname "$0")/common_functions.sh" ] && . "$(dirname "$0")/common_functions.sh"

# Check for required arguments
[ $# -lt 2 ] && { echo "Usage: $0 <directory> <type> [custom_name]"; exit 1; }

# Set the repository name
# If $3 is provided, use it. Otherwise, default to the type ($2).
if [ -z "$3" ]; then
    repo_name="${2}_${BRAND}_${DEVICE}"
else
    repo_name="${3}_${BRAND}_${DEVICE}"
fi

# Sanitize repo name (replace spaces/dots with underscores)
repo_name=$(echo "$repo_name" | tr ' .' '__')

target_dir="$1"
[ ! -d "$target_dir" ] && { echo "Error: Directory $target_dir not found"; exit 1; }

cd "$target_dir" || exit 1

# Initialize Git and prepare the branch
# We use a unique branch name based on the fingerprint to avoid conflicts
branch_name="${2}-${FINGERPRINT}"
git init -b "$branch_name"
git add -f .
git commit -s -m "Dump: $FINGERPRINT" || { Echo "No changes to commit for $repo_name, skipping push."; exit 0; } # Handle no changes

# Create the repository on GitHub and push the current branch
Echo "Attempting to create and push repository: $repo_name"

# Try to create the remote repo. If it fails, assume it already exists.
if ! gh repo create "$repo_name" --public > /dev/null 2>&1; then
    warn "Repository $repo_name might already exist or creation failed. Attempting to add remote and push."
fi

# Add the remote origin regardless, overwriting if it exists
git remote add origin "https://$UN:$GITHUB_TOKEN@github.com/$UN/$repo_name.git" 2>/dev/null || \
git remote set-url origin "https://$UN:$GITHUB_TOKEN@github.com/$UN/$repo_name.git"

# Push the current branch to origin, setting upstream
if git push -u origin "$branch_name" --force; then
    Echo "Successfully uploaded to: https://github.com/$UN/$repo_name"
else
    error "Failed to push to repository: $repo_name"
fi

cd - > /dev/null
