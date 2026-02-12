#!/usr/bin/env bash
set -euo pipefail

#===============================
#
#Logging Helpers
#
#===============================

log() {
command echo -e "[SCRIPT] $*"
}

error() {
command echo -e "[ERROR] $*" >&2
exit 1
}

xerror() {
if [[ -f xerr ]]; then
command echo -e "[ERROR] $\n$(cat xerr)" >&2
else
command echo -e "[ERROR] $" >&2
fi
exit 1
}

warn() {
command echo -e "[WARNING] $*"
}

#===============================
#
#Compression Utilities
#
#===============================

compress() {
[[ $# -lt 1 ]] && error "compress(): Missing file argument"
local file="$1"

[[ ! -f "$file" ]] && warn "File not found: $file" && return 0

local size
size=$(stat -c %s "$file" 2>/dev/null) || return 0

50MB limit (GitHub safe)

local limit=52428800

if [[ "$size" -gt "$limit" ]]; then
gzip -f "$file" &>xerr || xerror "Failed to compress $file"
log "Compressed: $file"
fi
}

compress_files() {
[[ $# -lt 1 ]] && error "compress_files(): Missing directory argument"
local dir="$1"

[[ ! -d "$dir" ]] && error "Directory not found: $dir"

find "$dir" -type f -size +50M -exec bash -c 'compress "$0"' {} ;
}

#===============================
#
#Property Extraction
#
#===============================

_get_prop() {
local key="$1"
shift
grep -h "^${key}=" "$@" 2>/dev/null | head -n1 | cut -d= -f2-
}

dump_props() {
[[ $# -lt 1 ]] && error "dump_props(): Missing working directory"
local workdir="$1"

[[ ! -d "$workdir" ]] && error "Directory not found: $workdir"

pushd "$workdir" >/dev/null || error "Cannot enter directory"

local fingerprint
fingerprint=$(_get_prop "ro.build.fingerprint" system/build*.prop system/system/build*.prop || true)
[[ -z "$fingerprint" ]] && fingerprint=$(_get_prop "ro.vendor.build.fingerprint" vendor/build*.prop || true)
[[ -z "$fingerprint" ]] && fingerprint=$(_get_prop "ro.bootimage.build.fingerprint" vendor/build.prop || true)

local brand
brand=$(_get_prop "ro.product.brand" system/build*.prop vendor/build*.prop || true)
[[ -z "$brand" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1 || true)

local codename
codename=$(_get_prop "ro.product.device" system/build*.prop vendor/build*.prop || true)
[[ -z "$codename" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1 || true)

local release
release=$(_get_prop "ro.build.version.release" system/build*.prop vendor/build*.prop || true)

[[ -z "$brand" ]] && error "Failed to determine BRAND"
[[ -z "$codename" ]] && error "Failed to determine DEVICE"
[[ -z "$fingerprint" ]] && error "Failed to determine FINGERPRINT"
[[ -z "$release" ]] && warn "VERSION not found"

export BRAND
export DEVICE
export FINGERPRINT
export VERSION="$release"

popd >/dev/null
}

dump_props_to_env_file() {
[[ $# -lt 1 ]] && error "dump_props_to_env_file(): Missing directory"
dump_props "$1"

cat > env <<EOF
export BRAND="$BRAND"
export DEVICE="$DEVICE"
export FINGERPRINT="$FINGERPRINT"
export VERSION="$VERSION"
EOF

log "Environment file written: env"
}

#===============================
#
#GitHub Auth
#
#===============================

git_auth() {
[[ $# -lt 3 ]] && error "git_auth(): Requires name, email, token"

local name="$1"
local email="$2"
local token="$3"

command -v gh >/dev/null || error "GitHub CLI not installed"

git config --global user.name "$name"
git config --global user.email "$email"

echo "$token" | gh auth login --with-token
log "GitHub authentication configured"
}
