#!/bin/bash

# Utility for consistent logging
Echo() { echo -e "[SCRIPT]: $*"; }
error() { echo -e "ERROR: $*" >&2; exit 1; }
warn() { echo -e "WARNING: $*" >&2; }
export -f Echo error warn

# Improved compression logic
compress() {
  local file="$1"
  [[ ! -f "$file" ]] && return 1
  
  local size=$(stat -c %s "$file")
  
  # Corrected comparison: use -gt instead of >
  if [ "$size" -gt 51380224 ]; then
    Echo "Compressing $file..."
    gzip -f "$file" || { warn "Failed to compress $file"; return 1; }
    Echo "Compressed: ${file}.gz"
  fi
}
export -f compress

compress_files() {
  # Corrected comparison: use -lt instead of <
  [ "$#" -lt 1 ] && error "Missing argument: working directory"
  [ ! -d "$1" ] && error "Directory not found: $1"

  Echo "Checking for large files in $1..."
  find "$1" -type f -size +50M -exec bash -c 'compress "$0"' {} \;
}

dump_props() {
  [ "$#" -lt 1 ] && error "Missing argument: working directory"
  local target_dir="$1"
  pushd "$target_dir" > /dev/null || error "Could not enter $target_dir"

  local prop_files=$(find . -name "build*.prop")
  
  local fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -h $prop_files | head -1)
  [[ -z "$fingerprint" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -h $prop_files | head -1)

  local brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -h $prop_files | head -1)
  [[ -z "$brand" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1)

  local codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -h $prop_files | head -1)
  [[ -z "$codename" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1)

  local release=$(grep -m1 -oP "(?<=^ro.build.version.release=).*" -h $prop_files | head -1)

  export BRAND=$(echo "$brand" | tr '[:upper:]' '[:lower:]' | xargs)
  export DEVICE=$(echo "$codename" | tr '[:upper:]' '[:lower:]' | xargs)
  export FINGERPRINT=$(echo "$fingerprint" | sed 's/[/:]/_/g')
  export VERSION="$release"
  
  popd > /dev/null
}

dump_props_to_env_file() {
  [ "$#" -lt 1 ] && error "Missing argument: working directory"
  dump_props "$1"
  
  local env_file="${GITHUB_WORKSPACE:-.}/env"

  {
    echo "export BRAND=$BRAND"
    echo "export DEVICE=$DEVICE"
    echo "export FINGERPRINT=$FINGERPRINT"
    echo "export VERSION=$VERSION"
    echo "export CODENAME=$DEVICE"
  } > "$env_file"
}

git_auth() {
  [ "$#" -lt 3 ] && error "Missing git auth arguments"
  
  # Fix for Exit Code 1: Clear GITHUB_TOKEN before login
  unset GITHUB_TOKEN
  
  git config --global user.name "$1"
  git config --global user.email "$2"
  
  # Perform login using the secret passed from the YAML
  echo "$3" | gh auth login --with-token
  
  # Set it for the current process
  export GITHUB_TOKEN="$3"
  Echo "Git and GitHub CLI authorized for $1"
}
