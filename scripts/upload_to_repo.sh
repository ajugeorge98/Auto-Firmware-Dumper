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
git add .
git commit -s -m "Dump: $FINGERPRINT"

# Create the repository on GitHub
# --source=. tells gh to use the current directory as the project root
# --push automatically pushes the local commits to the new remote
Echo "Creating and pushing repository: $repo_name"

if gh repo create "$repo_name" --public --source=. --remote=origin --push; then
    Echo "Successfully uploaded to: https://github.com/$UN/$repo_name"
else
    # Fallback if repo already exists: just try to push
    warn "Repository might already exist or creation failed. Attempting force push..."
    git remote add origin "https://github.com/$UN/$repo_name.git" 2>/dev/null
    git push -u origin "$branch_name" --force
fi

cd - > /dev/null
