#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common_functions.sh"

[[ $# -lt 2 ]] && error "Usage: upload_to_repo.sh <directory> <repo_prefix> [custom_name]"

WORK_DIR="$1"
PREFIX="$2"
CUSTOM_NAME="${3:-$2}"

[[ ! -d "$WORK_DIR" ]] && error "Directory not found: $WORK_DIR"

Ensure required environment variables exist

[[ -z "${BRAND:-}" ]] && error "BRAND not set (run dump_props first)"
[[ -z "${DEVICE:-}" ]] && error "DEVICE not set (run dump_props first)"
[[ -z "${FINGERPRINT:-}" ]] && error "FINGERPRINT not set (run dump_props first)"

SAFE_FP=$(echo "$FINGERPRINT" | tr '/:' '')
BRANCH_NAME="${PREFIX}-${SAFE_FP}"
REPO_NAME="${CUSTOM_NAME}${BRAND}_${DEVICE}"

cd "$WORK_DIR"

log "Initializing git repository..."
git init
git checkout -b "$BRANCH_NAME"
git add .
git commit -s -m "$FINGERPRINT"

command -v gh >/dev/null || error "GitHub CLI not installed"

log "Creating GitHub repository: $REPO_NAME"
gh repo create "$REPO_NAME" 
--public 
--source=. 
--remote=origin 
--push

log "Repository uploaded successfully."
